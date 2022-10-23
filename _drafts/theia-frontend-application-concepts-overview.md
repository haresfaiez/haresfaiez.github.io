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


# source code
- key files:
/workspaces/theia/packages/core/src/browser/browser.ts
/workspaces/theia/examples/playwright/src/theia-text-editor.ts



# Editor structure
- container div with children div as lines (div per line, with span children, token as span, space/white space as span)