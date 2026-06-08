/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: [
    "@web26/services-content",
    "@web26/ui-assets",
    "@web26/ui-library",
    "@web26/ui-tokens",
    "@web26/utils"
  ],
  images: {
    remotePatterns: [
      {
        protocol: "http",
        hostname: "localhost",
        port: "8080"
      }
    ]
  }
};

export default nextConfig;
