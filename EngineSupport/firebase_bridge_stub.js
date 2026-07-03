// Privacy-preserving replacement for GameHub's Firebase bridge.
// It keeps the internal event handshake alive while discarding every analytics event.
(async () => {
  const internals = window.__TAURI_INTERNALS__;
  if (!internals) return;

  const invoke = (command, args = {}) => internals.invoke(command, args);
  const listen = async (event, handler) => {
    const callback = internals.transformCallback(handler);
    return invoke("plugin:event|listen", {
      event,
      target: { kind: "Any" },
      handler: callback
    });
  };
  const emit = (event, payload) => invoke("plugin:event|emit", { event, payload });

  await listen("firebase-bridge-init", async () => {
    await emit("firebase-bridge-init-result", {
      success: false,
      error: "analytics_disabled_by_user"
    });
  });
  await listen("firebase-bridge-health-ping", async () => {
    await emit("firebase-bridge-health-pong", {
      ready: false,
      version: 1,
      privacy: "disabled"
    });
  });
  await listen("firebase-bridge-track-event", () => {});
  await listen("firebase-bridge-set-user-id", () => {});
  await listen("firebase-bridge-set-user-properties", () => {});

  await emit("firebase-bridge-loaded", {
    version: 1,
    privacy: "disabled"
  });
})();
