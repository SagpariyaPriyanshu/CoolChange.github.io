import { useEffect, useRef, useState } from "react";
import { mapLayers, type StoryLayer } from "../data/storyData";

type HeatMapProps = {
  activeStep: number;
  trees?: number;
  compact?: boolean;
};

function HeatRaster() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return undefined;

    const image = new Image();
    image.src = "/maps/clyde-north-uhi-2018.png";
    image.onload = () => {
      const context = canvas.getContext("2d", { willReadFrequently: true });
      if (!context) return;

      canvas.width = image.naturalWidth;
      canvas.height = image.naturalHeight;
      context.drawImage(image, 0, 0);
      const pixels = context.getImageData(0, 0, canvas.width, canvas.height);

      for (let pixel = 0; pixel < pixels.data.length; pixel += 4) {
        const red = pixels.data[pixel];
        const green = pixels.data[pixel + 1];
        const blue = pixels.data[pixel + 2];
        const alpha = pixels.data[pixel + 3];
        const isYellow = red > 210 && green > 175 && blue < 100;
        const isOrange = red > 190 && green >= 75 && green < 185 && blue < 110;
        const isRed = red > 170 && green < 120 && blue < 110;

        if (!alpha || isYellow) {
          pixels.data[pixel + 3] = 0;
        } else if (isOrange || isRed) {
          pixels.data[pixel] = isRed ? 221 : 238;
          pixels.data[pixel + 1] = isRed ? 49 : 86;
          pixels.data[pixel + 2] = 38;
          pixels.data[pixel + 3] = isRed ? 175 : 142;
        } else {
          pixels.data[pixel + 3] = 0;
        }
      }

      context.putImageData(pixels, 0, 0);
    };

    return () => { image.onload = null; };
  }, []);

  return <canvas ref={canvasRef} className="map-raster heat-raster" aria-hidden="true" />;
}

function ParkReserveRaster() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return undefined;

    const image = new Image();
    image.src = "/maps/clyde-north-mapbox.png";
    image.onload = () => {
      const context = canvas.getContext("2d", { willReadFrequently: true });
      if (!context) return;

      canvas.width = image.naturalWidth;
      canvas.height = image.naturalHeight;
      context.drawImage(image, 0, 0);
      const pixels = context.getImageData(0, 0, canvas.width, canvas.height);

      for (let pixel = 0; pixel < pixels.data.length; pixel += 4) {
        const red = pixels.data[pixel];
        const green = pixels.data[pixel + 1];
        const blue = pixels.data[pixel + 2];
        const isParkGreen = green > red + 11 && green > blue + 6 && green > 105 && red < 210;

        if (isParkGreen) {
          pixels.data[pixel] = 15;
          pixels.data[pixel + 1] = 108;
          pixels.data[pixel + 2] = 68;
          pixels.data[pixel + 3] = 126;
        } else {
          pixels.data[pixel + 3] = 0;
        }
      }

      context.putImageData(pixels, 0, 0);
    };

    return () => { image.onload = null; };
  }, []);

  return <canvas ref={canvasRef} className="map-raster park-reserve-raster" aria-hidden="true" />;
}

function mapLayerForStep(step: number): StoryLayer {
  if (step === 1) return "canopy";
  if (step === 3) return "future";
  return "heat";
}

export function HeatMap({ activeStep, trees = 0, compact = false }: HeatMapProps) {
  const [layer, setLayer] = useState<StoryLayer>(() => mapLayerForStep(activeStep));
  const cooling = Math.min(trees / 46, 0.72);
  const legend = mapLayers[layer];

  useEffect(() => {
    setLayer(mapLayerForStep(activeStep));
  }, [activeStep]);

  const mapClass = ["map-shell", compact && "map-shell-compact", `step-${activeStep}`, `layer-${layer}`]
    .filter(Boolean)
    .join(" ");

  return (
    <div className={mapClass}>
      <div className="map-surface">
        <img className="mapbox-image" src="/maps/clyde-north-mapbox.png" alt="Map of Clyde North, Victoria, showing streets, waterways and open space" />
        <HeatRaster />
        <ParkReserveRaster />
        <div className="heat-field" style={{ opacity: layer === "heat" ? Math.max(0.46, 0.76 - cooling * 0.24) : layer === "future" ? Math.max(0.28, 0.9 - cooling * 0.78) : 0 }} aria-hidden="true" />
        <div className="future-haze" style={{ opacity: layer === "future" ? Math.max(0.12, 0.66 - cooling * 0.68) : 0 }} aria-hidden="true" />
        <div className="place-pin"><span />Clyde North</div>
      </div>

      <div className="map-glass map-label"><span className="pulse-dot" />{legend.label}</div>
      <div className="map-tools" aria-label="Map layers">
        <button className={layer === "heat" ? "active" : ""} onClick={() => setLayer("heat")} type="button" aria-pressed={layer === "heat"}><span className="tool-icon heat-icon" />2026 heat</button>
        <button className={layer === "canopy" ? "active" : ""} onClick={() => setLayer("canopy")} type="button" aria-pressed={layer === "canopy"}><span className="tool-icon canopy-icon" />Canopy</button>
        <button className={layer === "future" ? "active" : ""} onClick={() => setLayer("future")} type="button" aria-pressed={layer === "future"}><span className="tool-icon future-icon" />2050 heat</button>
      </div>

      <div className="heat-scale"><span>{legend.low}</span><i /><span>{legend.high}</span></div>
      <p className="map-data-note">{legend.note}</p>
      <p className="map-credit">Baseline: Victorian Government 2018. © Mapbox © OpenStreetMap</p>
    </div>
  );
}
