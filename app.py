from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse, FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import pandas as pd
import numpy as np
import math
import os

# ======== CONFIG ========
CSV_PATH = os.environ.get("LDP_2024_public", "LPD_2024_public.csv")  # path to your full dataset CSV
LAT_COL = os.environ.get("LAT_COL", "Latitude")
LON_COL = os.environ.get("LON_COL", "Longitude")
NAME_COL = os.environ.get("NAME_COL", "Common_name")
ID_COL = os.environ.get("ID_COL", "ID")

# ======== APP ========
app = FastAPI(title="Nearest Animals API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class NearestQuery(BaseModel):
    lat: float = Field(..., description="User latitude in decimal degrees")
    lon: float = Field(..., description="User longitude in decimal degrees")
    k: int = Field(5, description="How many nearest animals to return (default 5)")

def load_data(csv_path: str) -> pd.DataFrame:
    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"CSV not found at {csv_path}. Set ANIMALS_CSV env or place file next to app.py")
    df = pd.read_csv(csv_path)
    # Basic validation
    for col in [LAT_COL, LON_COL]:
        if col not in df.columns:
            raise ValueError(f"Column '{col}' not found in CSV. Available: {list(df.columns)}")
    return df

def haversine_km(lat1, lon1, lat2, lon2):
    # Vectorized haversine, inputs in degrees
    R = 6371.0
    phi1 = np.radians(lat1)
    phi2 = np.radians(lat2)
    dphi = np.radians(lat2 - lat1)
    dlmb = np.radians(lon2 - lon1)

    a = np.sin(dphi / 2.0) ** 2 + np.cos(phi1) * np.cos(phi2) * np.sin(dlmb / 2.0) ** 2
    c = 2 * np.arctan2(np.sqrt(a), np.sqrt(1 - a))
    return R * c

# Convert numpy/pandas scalars and NaN to native Python types
def to_py(v):
    try:
        if isinstance(v, (np.integer, np.floating, np.bool_)):
            return v.item()
        if isinstance(v, np.ndarray):
            return v.tolist()
        if pd.isna(v):
            return None
    except Exception:
        pass
    return v

# Load dataset at startup
try:
    DATAFRAME = load_data(CSV_PATH)
    # Pre-extract coordinate arrays for speed
    LAT_ARR = DATAFRAME[LAT_COL].to_numpy(dtype=float)
    LON_ARR = DATAFRAME[LON_COL].to_numpy(dtype=float)
except Exception as e:
    # Defer failing until first API call; helps the user see the error more clearly
    DATAFRAME = None
    LAT_ARR = None
    LON_ARR = None
    STARTUP_ERROR = str(e)
else:
    STARTUP_ERROR = None

@app.get("/", response_class=HTMLResponse)
def root():
    # Serve the static index.html located next to app.py
    index_path = os.path.join(os.path.dirname(__file__), "index.html")
    if os.path.exists(index_path):
        with open(index_path, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read(), status_code=200)
    return HTMLResponse("<h1>Nearest Animals API</h1><p>index.html not found.</p>", status_code=200)

@app.get("/health")
def health():
    if STARTUP_ERROR:
        return {"status": "error", "detail": STARTUP_ERROR}
    return {"status": "ok", "rows": None if DATAFRAME is None else len(DATAFRAME)}

@app.post("/nearest")
def nearest(q: NearestQuery):
    if STARTUP_ERROR:
        raise HTTPException(status_code=500, detail=f"Startup error: {STARTUP_ERROR}")
    if DATAFRAME is None or LAT_ARR is None or LON_ARR is None:
        raise HTTPException(status_code=500, detail="Data not loaded. Check CSV path and columns.")

    if q.k <= 0:
        raise HTTPException(status_code=400, detail="k must be positive")

    # compute distances vectorized
    dists = haversine_km(q.lat, q.lon, LAT_ARR, LON_ARR)

    actual_k = min(q.k, len(dists))
    if actual_k == 0:
        return {"results": []}

    idx = np.argpartition(dists, kth=actual_k - 1)[:actual_k]
    # sort the selected indices by actual distance
    idx = idx[np.argsort(dists[idx])]

    out = []
    for i in idx:
        row = DATAFRAME.iloc[int(i)]
        out.append({
            "ID": to_py(row.get(ID_COL, None)),
            "Common_name": to_py(row.get(NAME_COL, None)),
            "Latitude": to_py(row.get(LAT_COL, None)),
            "Longitude": to_py(row.get(LON_COL, None)),
            "Distance_km": float(dists[i])
        })
    return {"results": out}
