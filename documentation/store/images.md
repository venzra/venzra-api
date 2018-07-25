## Store :: Images

Images are a key part to the store with products being the primary use however also areas like subscriptions and locations will reference images.

### Retrieve an image

Access binary data for a particular image, the image data is streamed directly as a response.

#### Request

**URL Parameters**

- **imageId**  
  This is the reference identifier for the image which is unique in the database.

```http
GET /store/images/:imageId HTTP/1.1
```

#### Response

Content type header will match to the file type e.g. `image/jpeg` or `image/png` which was originally uploaded following any adjustments made by the server to optimise the image.

```http
HTTP/1.1 200 OK
Content-Type: image/jpeg

** binary image data **
```
