// content.js
window.addEventListener('keydown', function(e) {
    e.preventDefault();      // stop the default browser action
    e.stopImmediatePropagation(); // stop propagation
}, true);
