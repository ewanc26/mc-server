# Troubleshooting

* **Server not starting:**  
Check `docker compose logs mc`, ensure Docker is running, and that the EULA is accepted.

* **Connection issues:**  
Confirm port `25565` is open, the server is online, the Minecraft client version matches, and DuckDNS is updating correctly.

* **Plugins failing:**  
Inspect the server logs for compatibility errors or syntax issues in `compose.yml`.
