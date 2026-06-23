import { ImageResponse } from "next/og";

export const runtime = "edge";
export const alt = "Belight Bible — Leia, destaque e estude a Bíblia em Português.";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OgImage() {
  return new ImageResponse(
    (
      <div
        style={{
          background: "#14110d",
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          padding: "80px",
          fontFamily: "Georgia, serif",
        }}
      >
        <div
          style={{
            width: "56px",
            height: "3px",
            background: "#c8902a",
            borderRadius: "2px",
            marginBottom: "48px",
          }}
        />
        <div
          style={{
            fontSize: "80px",
            fontWeight: "700",
            color: "#f3efe7",
            textAlign: "center",
            lineHeight: 1.1,
            marginBottom: "28px",
            letterSpacing: "-1px",
          }}
        >
          Belight Bible
        </div>
        <div
          style={{
            fontSize: "30px",
            color: "#a59d90",
            textAlign: "center",
            lineHeight: 1.5,
            maxWidth: "780px",
          }}
        >
          Leia, destaque e estude a Bíblia em Português.
        </div>
        <div
          style={{
            marginTop: "56px",
            fontSize: "20px",
            color: "#c8902a",
            letterSpacing: "0.05em",
          }}
        >
          belightbible.com
        </div>
      </div>
    ),
    { ...size },
  );
}
