## Account Identity

This is a set of endpoints used to enable account access with the ability to create a new subscriber.

### Registration

Create a new user account on Venzra who will become a new customer with a new store generated. On creation of an account the email address provided will be sent a message which contains details on how to complete their account setup and login.

#### Request

A request will be rejected if the terms flag is not set, on storing the date of this request is used in the database for when terms were last accepted (or in the case of registration the first time)

```http
POST /admin/identity HTTP/1.1
Content-Type: application/json

{
  "identity": "example@venzra.com",
  "acceptTerms": true
}
```

#### Response

Note that the valid status returned here are `REGISTERED` or `RECOVERY` the recovery occurs when an account has previously registered but not activated as such are attempting to register again.

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "_id": "123412341234123412341234",
  "identity": "example@venzra.com",
  "terms": "2018-01-01T00:00:00.000Z",
  "status": "REGISTERED",
  "created": "2018-01-01T00:00:00.000Z",
  "updated": "2018-01-01T00:00:00.000Z",
}
```
