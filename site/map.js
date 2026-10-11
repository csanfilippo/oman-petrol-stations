// Brand names are the `brand` property emitted by GeoJSONPetrolStationSerializer.
const BRAND_COLORS = {
  "Oman Oil": "#e4572e",
  "Shell": "#f2b705",
  "Al Maha": "#2a7fd4",
};
const UNKNOWN_BRAND_COLOR = "#7a828c";

const OMAN_BOUNDS = [[51.9, 16.6], [59.9, 26.4]];

const map = new maplibregl.Map({
  container: "map",
  style: "https://tiles.openfreemap.org/styles/liberty",
  bounds: OMAN_BOUNDS,
});
map.addControl(new maplibregl.NavigationControl(), "top-right");
map.addControl(new maplibregl.GeolocateControl({ trackUserLocation: true }), "top-right");

const visibleBrands = new Set();

try {
  const [snapshot] = await Promise.all([loadSnapshot(), map.once("load")]);
  brandsOf(snapshot.stations).forEach((brand) => visibleBrands.add(brand));
  showStations(snapshot.stations);
  renderBrandFilter(snapshot.stations);
  renderStatus(snapshot);
} catch (error) {
  document.getElementById("status").textContent = `Could not load stations (${error.message}).`;
}

async function loadSnapshot() {
  const response = await fetch("stations.geojson");
  if (!response.ok) {
    throw new Error(`stations.geojson: HTTP ${response.status}`);
  }
  const lastModified = response.headers.get("Last-Modified");
  return {
    stations: await response.json(),
    updatedAt: lastModified ? new Date(lastModified) : null,
  };
}

function brandsOf(stations) {
  return [...new Set(stations.features.map((f) => f.properties.brand))].sort();
}

function stationsOfVisibleBrands(stations) {
  return {
    type: "FeatureCollection",
    features: stations.features.filter((f) => visibleBrands.has(f.properties.brand)),
  };
}

function brandColorExpression() {
  return ["match", ["get", "brand"], ...Object.entries(BRAND_COLORS).flat(), UNKNOWN_BRAND_COLOR];
}

function showStations(stations) {
  map.addSource("stations", {
    type: "geojson",
    data: stations,
    cluster: true,
    clusterRadius: 45,
    clusterMaxZoom: 12,
  });

  map.addLayer({
    id: "clusters",
    type: "circle",
    source: "stations",
    filter: ["has", "point_count"],
    paint: {
      "circle-color": "#2f3a46",
      "circle-opacity": 0.85,
      "circle-radius": ["step", ["get", "point_count"], 14, 10, 18, 50, 24],
      "circle-stroke-width": 2,
      "circle-stroke-color": "#fff",
    },
  });

  map.addLayer({
    id: "cluster-count",
    type: "symbol",
    source: "stations",
    filter: ["has", "point_count"],
    layout: {
      "text-field": ["get", "point_count_abbreviated"],
      "text-font": ["Noto Sans Bold"],
      "text-size": 12,
    },
    paint: { "text-color": "#fff" },
  });

  map.addLayer({
    id: "stations",
    type: "circle",
    source: "stations",
    filter: ["!", ["has", "point_count"]],
    paint: {
      "circle-color": brandColorExpression(),
      "circle-radius": 7,
      "circle-stroke-width": 2,
      "circle-stroke-color": "#fff",
    },
  });

  map.on("click", "clusters", async (event) => {
    const [cluster] = event.features;
    const zoom = await map.getSource("stations").getClusterExpansionZoom(cluster.properties.cluster_id);
    map.easeTo({ center: cluster.geometry.coordinates, zoom });
  });

  map.on("click", "stations", (event) => {
    const [station] = event.features;
    new maplibregl.Popup({ offset: 10 })
      .setLngLat(station.geometry.coordinates)
      .setDOMContent(stationPopup(station))
      .addTo(map);
  });

  for (const layer of ["clusters", "stations"]) {
    map.on("mouseenter", layer, () => { map.getCanvas().style.cursor = "pointer"; });
    map.on("mouseleave", layer, () => { map.getCanvas().style.cursor = ""; });
  }
}

// Built with textContent, never innerHTML: station names are scraped from provider pages.
function stationPopup(station) {
  const [longitude, latitude] = station.geometry.coordinates;
  const container = document.createElement("div");
  container.className = "station-popup";

  const name = document.createElement("strong");
  name.textContent = station.properties.stationName;

  const brand = document.createElement("span");
  brand.className = "brand";
  brand.textContent = station.properties.brand;

  const directions = document.createElement("a");
  directions.href = `https://www.google.com/maps/dir/?api=1&destination=${latitude},${longitude}`;
  directions.target = "_blank";
  directions.rel = "noopener";
  directions.textContent = "Directions";

  container.append(name, brand, document.createElement("br"), directions);
  return container;
}

function renderBrandFilter(stations) {
  const list = document.getElementById("brands");
  for (const brand of brandsOf(stations)) {
    const count = stations.features.filter((f) => f.properties.brand === brand).length;

    const checkbox = document.createElement("input");
    checkbox.type = "checkbox";
    checkbox.checked = true;
    checkbox.addEventListener("change", () => {
      checkbox.checked ? visibleBrands.add(brand) : visibleBrands.delete(brand);
      map.getSource("stations").setData(stationsOfVisibleBrands(stations));
    });

    const swatch = document.createElement("span");
    swatch.className = "swatch";
    swatch.style.background = BRAND_COLORS[brand] ?? UNKNOWN_BRAND_COLOR;

    const name = document.createElement("span");
    name.textContent = brand;

    const total = document.createElement("span");
    total.className = "count";
    total.textContent = count;

    const label = document.createElement("label");
    label.append(checkbox, swatch, name, total);

    const item = document.createElement("li");
    item.append(label);
    list.append(item);
  }
}

function renderStatus({ stations, updatedAt }) {
  const updated = updatedAt
    ? ` · updated ${updatedAt.toLocaleDateString(undefined, { dateStyle: "medium" })}`
    : "";
  document.getElementById("status").textContent = `${stations.features.length} stations${updated}`;
}
