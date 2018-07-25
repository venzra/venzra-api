## Website :: Support

These endpoints are to assist users in their day to day operations when using Venzra as an ecommerce platform.

### Contact us

Enables a user to send an email to the support team at Venzra, the destination of this email is configured in the API config on the running environment.

#### Request

```http
POST /website/support/contact HTTP/1.1
Content-Type: application/json

{
  "alias": "Example user",
  "emailAddress": "example@venzra.com",
  "reason": "Type of request",
  "message": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque fermentum at magna eu mattis."
}
```

#### Response

```http
HTTP/1.1 202 Accepted
```

### User guides

These are guides to assist users in how to utilise the platform.

#### Request

There are two parameters available to access guides;

- **section**  
  This is the folder in which the guide exists
- **page**  
  This is the actual markdown page which also supports json meta tagging

```http
GET /website/support/guides/:section/:page HTTP/1.1
```

#### Response

| field | description |
| :--- | :--- |
| title | Often present and can be used at the top of a page |
| content | This is the content to be displayed, it is the only field that will always be present, other fields are optional in if they might appear |

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "title": "Lorem ipsum dolor sit amet",
  "content": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque fermentum at magna eu mattis."
}
```
