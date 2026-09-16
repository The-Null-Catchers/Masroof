import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Masroof · مصروف",
    short_name: "Masroof",
    description: "Bilingual personal finance: accounts, spending and transfers.",
    start_url: "/",
    display: "standalone",
    background_color: "#07463D",
    theme_color: "#0F7A68",
    icons: [
      { src: "/icon-192.png", sizes: "192x192", type: "image/png" },
      { src: "/icon-512.png", sizes: "512x512", type: "image/png" },
      { src: "/icon-maskable-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
  };
}
