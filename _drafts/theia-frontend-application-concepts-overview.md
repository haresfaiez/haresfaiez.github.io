- Create a DI container using `inversifyJS`, configures it with frontend modules.
- `FrontEndApplication#start` starts the frontend application
```
    /**
     * Start the frontend application.
     *
     * Start up consists of the following steps:
     * - start frontend contributions
     * - attach the application shell to the host element
     * - initialize the application shell layout
     * - reveal the application shell if it was hidden by a startup indicator
     */
```
- Theia uses PhosphorJS to manage widgets