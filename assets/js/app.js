
// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import "../css/app.css"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"
import "./scripts.js"
// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "./vendor/some-package.js"
//
// Alternatively, you can `npm install some-package` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import { addCommasToNumber, formatDateTime, addPercent, secondsToHHMMSS } from "../src/formats.ts";
import { init as initInfantryModel } from "../src/character/planetside-model.ts";
import { init as initWeaponsTable } from "../src/character/weapons-table.ts";
import { init as initWeapons } from "../src/character/weapons.ts";

// Init Hooks
let Hooks = {};

// Format the given element when it is added or updated
Hooks.NewDateToFormat = {
  mounted () {
    formatDateTime(this.el);
  },
  updated () {
    formatDateTime(this.el);
  }
};

Hooks.AddCommasToNumber = {
  mounted () {
    addCommasToNumber(this.el);
  },
  updated () {
    addCommasToNumber(this.el);
  }
};

Hooks.AddPercent = {
  mounted () {
    addPercent(this.el);
  },
  updated () {
    addPercent(this.el);
  }
};

Hooks.SecondsToReadable = {
  mounted () {
    secondsToHHMMSS(this.el);
  },
  updated () {
    secondsToHHMMSS(this.el);
  }
};

Hooks.InitInfantryModel = {
  mounted () {
    initInfantryModel(this.el);
  },
  updated () {
    initInfantryModel(this.el);
  }
};

Hooks.InitWeaponsTable = {
  mounted () {
    console.log("wow starting")
    //initialize bootstrap table
    $('#weaponTable').bootstrapTable();
    console.log('yep that worked')
    //initialize weapon sorters
    function timeSorter (a, b) {
      var aa = getTimeInSeconds(a);
      var bb = getTimeInSeconds(b);
      return aa - bb;
    }

    function getTimeInSeconds (time) {
      var div = document.createElement('div');
      div.innerHTML = time.trim();

      return +div.firstChild.innerHTML;
    }
    console.log('MOUNT')
    initWeaponsTable();
    initWeapons();
  },
  updated () {
    console.log('UPDATED')
    initWeaponsTable();
    initWeapons();
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: { _csrf_token: csrfToken } })

// Show progress bar on live navigation and form submits
topbar.topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", info => topbar.topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
