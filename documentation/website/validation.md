## Validations

A set of common validators which can be used to assit in checking input of data.

### Password

Simple password strength validation checking service, provided by the zxcvbn library.

#### Request

```http
POST /website/validation/password HTTP/1.1
Content-Type: application/json

{
  "password": "MyPassword123"
}
```

#### Response

| field | description |
| :--- | :--- |
| score | A score from 0-4 based on the cryptography entropy / chance of being brute forced (lower score is less secure) |
| message | Associated message giving a short explanation on how to improve the password strength score |

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "score": 1,
  "message": "This is similar to a commonly used password",
}
```
