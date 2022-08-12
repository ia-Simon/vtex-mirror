package main

import (
	"github.com/gofiber/fiber/v2"
)

func main() {
	app := fiber.New()

	app.All("*", func(c *fiber.Ctx) error {
		method := c.Method()
		endpoint := c.OriginalURL()
		// headers := c.GetReqHeaders()

		return c.SendString(method + " <|> " + endpoint + "\n")
	})

	app.Listen(":8080")
}
