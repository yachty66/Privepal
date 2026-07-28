import { ImageResponse } from "next/og";
import { readFile } from "node:fs/promises";
import { join } from "node:path";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";
export const alt = "Privepal: fast, private AI chat";

export default async function Image() {
  const logo = await readFile(join(process.cwd(), "public", "logo.png"));
  const logoSrc = `data:image/png;base64,${logo.toString("base64")}`;

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          backgroundColor: "#000000",
          color: "#ffffff",
        }}
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={logoSrc} width={150} height={150} alt="" />
        <div
          style={{
            display: "flex",
            alignItems: "baseline",
            gap: 20,
            marginTop: 10,
          }}
        >
          <div style={{ fontSize: 92, fontWeight: 700, letterSpacing: -3 }}>
            Privepal
          </div>
          <div
            style={{
              fontSize: 26,
              color: "#737373",
              border: "2px solid #404040",
              borderRadius: 999,
              padding: "2px 18px",
            }}
          >
            BETA
          </div>
        </div>
        <div style={{ fontSize: 40, color: "#a3a3a3", marginTop: 6 }}>
          Fast. Private. Yours.
        </div>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 14,
            marginTop: 44,
            fontSize: 28,
            color: "#d4d4d4",
          }}
        >
          <div
            style={{
              width: 16,
              height: 16,
              borderRadius: 999,
              backgroundColor: "#22c55e",
            }}
          />
          AI chat nobody can read. Not even us. Open source.
        </div>
        <div
          style={{
            position: "absolute",
            bottom: 36,
            fontSize: 26,
            color: "#525252",
          }}
        >
          privepal.com
        </div>
      </div>
    ),
    size
  );
}
