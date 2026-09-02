export function resolveMapStyle(token: string | undefined) {
  const hasPublicToken = Boolean(token?.startsWith("pk."));
  return {
    accessToken: hasPublicToken ? token : undefined,
    style: "mapbox://styles/mapbox/light-v11",
  };
}
