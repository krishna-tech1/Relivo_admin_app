import uvicorn

if __name__ == "__main__":
    print("Starting Admin Backend on Port 8001...")
    uvicorn.run("app.main:app", host="0.0.0.0", port=8001, reload=True)
