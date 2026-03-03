# Catsy Coffee

## API Data Structures

### Product Model
Both the Web and Mobile applications share a standardized `Product` model. The `GET /api/products` endpoint returns JSON arrays populated with objects matching this shape:

```json
{
  "id": 1,
  "product_name": "Espresso",
  "price": 3.50,
  "image_url": "https://example.com/espresso.png"
}
```

#### Flutter / Mobile Usage
The Flutter SDK includes a `Product.fromJson` factory that automatically parses `product_name` to `product.name` and `image_url` to `product.imageUrl` to guarantee type safety and idiomatic Dart syntax. Developers can access `product.name` directly instead of referencing `json['product_name']`.

#### React / Web Usage
Web developers using `api.js` will receive the raw JSON format above. Standardize components to use `.product_name` and `.image_url` or map them to camelCase at the query level if preferred.
