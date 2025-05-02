package sub

import (
	"encoding/base64"
	"net"
	"strings"

	"github.com/gin-gonic/gin"
)

type SUBController struct {
	subPath        string
	subJsonPath    string
	subEncrypt     bool
	updateInterval string

	jsonRules      string
	subService     *SubService
	subJsonService *SubJsonService
}

func NewSUBController(
	g *gin.RouterGroup,
	subPath string,
	jsonPath string,
	encrypt bool,
	showInfo bool,
	rModel string,
	update string,
	jsonFragment string,
	jsonNoise string,
	jsonMux string,
	jsonRules string,
) *SUBController {
	sub := NewSubService(showInfo, rModel)
	subJson := NewSubJsonService(jsonFragment, jsonNoise, jsonMux, jsonRules, sub)
	a := &SUBController{
		subPath:        subPath,
		subJsonPath:    jsonPath,
		subEncrypt:     encrypt,
		updateInterval: update,

		jsonRules:      jsonRules,
		subService:     sub,
		subJsonService: subJson,
	}
	a.initRouter(g)
	return a
}

func (a *SUBController) initRouter(g *gin.RouterGroup) {
	g.Group(a.subPath).GET(":subid", a.subs)
	g.Group(a.subJsonPath).GET(":subid", a.subJsons)
}

func (a *SUBController) subs(c *gin.Context) {
	subId := c.Param("subid")
	var host string
	if h, err := getHostFromXFH(c.GetHeader("X-Forwarded-Host")); err == nil {
		host = h
	}
	if host == "" {
		host = c.GetHeader("X-Real-IP")
	}
	if host == "" {
		var err error
		host, _, err = net.SplitHostPort(c.Request.Host)
		if err != nil {
			host = c.Request.Host
		}
	}
	subs, header, err := a.subService.GetSubs(subId, host)
	if err != nil || len(subs) == 0 {
		c.String(400, "Error!")
	} else {
		result := ""
		for _, sub := range subs {
			result += sub + "\n"
		}

		// Add headers
		c.Writer.Header().Set("Profile-Title", subId)
		c.Writer.Header().Set("Subscription-Userinfo", header)
		c.Writer.Header().Set("Profile-Update-Interval", a.updateInterval)

		// v2RayTun iOS routing support
		r, _ := a.subJsonService.GetRouting(a.jsonRules)
		c.Writer.Header().Set("Routing", base64.StdEncoding.EncodeToString(r))

		if a.subEncrypt {
			c.String(200, base64.StdEncoding.EncodeToString([]byte(result)))
		} else {
			c.String(200, result)
		}
	}
}

func (a *SUBController) subJsons(c *gin.Context) {
	subId := c.Param("subid")
	var host string
	if h, err := getHostFromXFH(c.GetHeader("X-Forwarded-Host")); err == nil {
		host = h
	}
	if host == "" {
		host = c.GetHeader("X-Real-IP")
	}
	if host == "" {
		var err error
		host, _, err = net.SplitHostPort(c.Request.Host)
		if err != nil {
			host = c.Request.Host
		}
	}
	jsonSub, header, err := a.subJsonService.GetJson(subId, host)
	if err != nil || len(jsonSub) == 0 {
		c.String(400, "Error!")
	} else {

		// Add headers
		c.Writer.Header().Set("subscription-userinfo", header)
		c.Writer.Header().Set("profile-update-interval", a.updateInterval)
		c.Writer.Header().Set("profile-title", subId)

		c.Writer.Header().Set("update-always", "true")
		c.Writer.Header().Set("announce", "💜 По всем вопросам обращайтесь в #7854BAподдержку!")
		c.Writer.Header().Set("announce-url", "https://t.me/userlay_support")

		// v2RayTun iOS routing support
		r, _ := a.subJsonService.GetRouting(a.jsonRules)
		c.Writer.Header().Set("routing", base64.StdEncoding.EncodeToString(r))

		c.String(200, jsonSub)
	}
}

func getHostFromXFH(s string) (string, error) {
	if strings.Contains(s, ":") {
		realHost, _, err := net.SplitHostPort(s)
		if err != nil {
			return "", err
		}
		return realHost, nil
	}
	return s, nil
}
