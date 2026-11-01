/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: [
    "@web26/services-content",
    "@web26/ui-assets",
    "@web26/ui-library",
    "@web26/ui-tokens",
    "@web26/utils"
  ]
  // No remote image patterns yet. Add the CMS media origin here when
  // Drupal-backed images are rendered; Next 16 blocks local-IP origins
  // unless `images.dangerouslyAllowLocalIP` is set.
};

export default nextConfig;
