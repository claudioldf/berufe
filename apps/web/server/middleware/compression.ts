import { constants } from "node:zlib";
import compression from "compression";

// Compresses the server-rendered HTML, JSON and XML responses. Production
// runs `node .output/server/index.mjs` behind Railway's edge, which does not
// compress, so without this every page ships uncompressed. Files under
// public/ and /_nuxt are precompressed at build time (`compressPublicAssets`).
//
// This is a middleware, so it wraps the response *outside* the `swr` route
// cache: the cache stores the plain body and each visitor gets the encoding
// their browser asked for.
const compress = compression({
  threshold: 1024,
  // Node's default Brotli quality (11) is far too slow to run per request;
  // 4 is the usual choice for on-the-fly responses.
  brotli: { params: { [constants.BROTLI_PARAM_QUALITY]: 4 } },
});

export default fromNodeMiddleware((req, res, next) => {
  if (import.meta.dev) return next();
  return compress(req, res, next);
});
