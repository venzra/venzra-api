## Account Identity

This is a set of endpoints used to manage account access with the ability to login (creation of access tokens) and recover credentials.

### Forgotten password

Perform the process of recovering account credentials, on calling this if a user account exists then an email is sent to the account holder which will allow them to reset their password for a period 8 hours.

#### Request

```http
POST /admin/identity HTTP/1.1
Content-Type: application/json

{
  "identity": "example@venzra.com"
}
```

#### Response

```http
HTTP/1.1 202 Accepted
```
