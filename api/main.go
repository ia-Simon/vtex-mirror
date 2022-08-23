package main

import (
	"bytes"
	"net/http"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
	app := fiber.New()

	app.Use(recover.New())

	app.All("*", func(c *fiber.Ctx) error {
		method := c.Method()
		endpoint := c.OriginalURL()
		headers := c.GetReqHeaders()
		body := c.Body()

		vtexStoreKey, vtexStoreToken, err := retrieveVtexStoreKeys(headers["X-Alfred-Store-Key"])
		if err != nil {
			panic(err)
		}

		vtexUrl := strings.Join([]string{"https://", headers["X-Vtex-Store-Domain"], endpoint}, "")
		req, err := http.NewRequest(method, vtexUrl, bytes.NewBuffer(body))
		if err != nil {
			panic(err)
		}
		req.Header.Set("X-VTEX-API-AppKey", vtexStoreKey)
		req.Header.Set("X-VTEX-API-AppToken", vtexStoreToken)
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			panic(err)
		}
		defer resp.Body.Close()

		return c.Status(resp.StatusCode).SendStream(resp.Body)
	})

	app.Listen(":8080")
}

func retrieveVtexStoreKeys(storeKey string) (string, string, error) {
	return "", "", nil
}
