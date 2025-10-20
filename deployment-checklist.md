# Deployment Checklist

This checklist summarizes the results of the pre-deployment sanity testing.

- [x] Builds pass
- [ ] Tests pass
- [ ] Local runtime OK
- [ ] Docker OK
- [ ] Azure: Clone repo, `docker compose up -d`, access via VM IP:4200

## Notes

*   **Tests:** The backend unit tests passed, but the frontend unit tests were skipped due to environmental issues. The API smoke tests failed.
*   **Local runtime:** The application is not functional. The microservices are failing to start and register with the Eureka server.
*   **Docker:** The Docker containers are running, but the services are not healthy.
*   **Azure:** The application is not ready for deployment.
