'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "1654f7e23b36e747548f4c9ca8bc4a48",
"version.json": "174b18a682c4fc750c9222227c0ea456",
"index.html": "5151c849bd5e1b421b00551bb66317d1",
"/": "5151c849bd5e1b421b00551bb66317d1",
"main.dart.js": "f791ccaa96db3463dc1918ab1b7c6477",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "8e509a37e697f8c81233e9c95bffb5f5",
"assets/AssetManifest.json": "19a9cdb5063abfb8eb2c0f65fb65a0de",
"assets/NOTICES": "eddd8476f2ce13e42d9ec5ee95562fb6",
"assets/FontManifest.json": "7e4a006594fdcc3d2533854104743c99",
"assets/AssetManifest.bin.json": "6f9daaa61d7c1cc91da5a68910f71771",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "92fb04fc0551c7e07f2d55a45117843f",
"assets/fonts/MaterialIcons-Regular.otf": "f0c9eb6c2dfd25e8158ecbeeec6fbc85",
"assets/assets/images/7-or.png": "d83ec17c632379955be9b48093ae290f",
"assets/assets/images/start_button.png": "ed3c79fcec5d7d5891a277e43904f97d",
"assets/assets/images/boss2.png": "323471058c73e684d0601e46bbf0f708",
"assets/assets/images/blue_coin.png": "20dff433ef7125123c0150f8c621121c",
"assets/assets/images/shadowblades.png": "949fce78b4ac030fdf5d830f07a04289",
"assets/assets/images/8.png": "725dcb82ba487aa033f4ec4109106684",
"assets/assets/images/whispering_flames.png": "88d84e3e6261195bde50fc62e55392b8",
"assets/assets/images/9-or.png": "0d11e25d916fc4a5d1bd4dd4fc54188f",
"assets/assets/images/whisper_warrior_attack.png": "4145900ac7c91d557299c21108cb2228",
"assets/assets/images/9.png": "b1c8edcbc2c331024b551ba6684c0442",
"assets/assets/images/5-or.png": "ccc838d0819652e3f2423746dd322ee7",
"assets/assets/images/chrono_echo.png": "770baef925f94e4766f05cdf6a04c862",
"assets/assets/images/unholy_fortitude.png": "d53e6a0376bbfd19e00ac2a4aae64a14",
"assets/assets/images/umbral_fang.png": "256b3affb58131ef98460be98f79100d",
"assets/assets/images/1-or.png": "ee9a6d01447931d4a41f3d61d576a23e",
"assets/assets/images/options_button.png": "8d9c41fc95f1d0c393345deb5555da1c",
"assets/assets/images/3-or.png": "3ea7a96a1eef9803de80efb00911228c",
"assets/assets/images/main_menu_background.png": "a873eef6a7735b8768983eb8110752af",
"assets/assets/images/mob1.png": "10b338dd33247f25a3ff2875efcea2ec",
"assets/assets/images/boss_projectile.png": "b8f0184e6d0c055a33024c1323c8f500",
"assets/assets/images/shadow_blades.png": "87f41507db2fa2c833de6b2b3740bb03",
"assets/assets/images/boss1_walk.png": "1f03792613e2bf33e4ba0df1653eb81f",
"assets/assets/images/mob2.png": "1b79eb6b19abe60671006d3ef09ae2b8",
"assets/assets/images/lootbox.png": "c17dc403735bfc6308cc0f582880aa93",
"assets/assets/images/revenants_stride.png": "49acad225beb3ac333abfdf634d43aa1",
"assets/assets/images/whisper_warrior_death.png": "170edec47534e9899fc304800a891d07",
"assets/assets/images/minus.png": "65cc4c62897c7e7843db83af505896ad",
"assets/assets/images/veil_of_the_forgotten.png": "a414597f5b23e0303374bf71e50fa5b1",
"assets/assets/images/shard_of_umbrathos.png": "4295b34bafd5ed9f1839d051d6162f12",
"assets/assets/images/fading_crescent.png": "a1ef06a3faec3b85ba5a537d99c0cbda",
"assets/assets/images/6-or.png": "55c75dff625e9bb0feb95364e0dec189",
"assets/assets/images/grass_map.png": "2c91875de4e14245ad6f83ef7ab79f6a",
"assets/assets/images/will_of_the_forgotten.png": "29e6c8d5e818a7ea77be3e3f18bda41e",
"assets/assets/images/fire_aura.png": "a3cfa8e6092bfa565b3e8edce7456364",
"assets/assets/images/gold_coin.png": "41f6395f9c01d05f9e6733338fbcf776",
"assets/assets/images/whisper_warrior_idle.png": "552af1e84fbb57830a8ef75c6380e528",
"assets/assets/images/8-or.png": "855bbfe3b1b78b59667dcd6f7fdb38f9",
"assets/assets/images/4-or.png": "527bcf44741a08f1d16fd0b0ce32a827",
"assets/assets/images/cursed_echo.png": "9e583cd46dd8f351195675312a3e28aa",
"assets/assets/images/boss1_idle.png": "412eabb0b574875fdfaa3ff0b6ace3b6",
"assets/assets/images/whisper_warrior_hit.png": "07c942161a16d4cdf40df4871da398ca",
"assets/assets/images/time_dilation.png": "daab07677a17185407989d9c8ebf4210",
"assets/assets/images/boss1_stagger.png": "20195f445518359a88efcdaaf5a7c1f7",
"assets/assets/images/4.png": "4622e02b91d8d0edfe5b59635d3d09a8",
"assets/assets/images/0-or.png": "baa6d682312edb7b88ed9a4ab57d4dde",
"assets/assets/images/vampiric_touch.png": "4b5cf13a3b04bdb1ee9c52f88bc44401",
"assets/assets/images/5.png": "25d39c520381805c8662f7a05dfd9061",
"assets/assets/images/projectile_normal.png": "34909edaa10f4d089bb0e87eb65317b1",
"assets/assets/images/7.png": "9fed743c042624de3e796d87df6f8515",
"assets/assets/images/6.png": "f828a2f3882efcca4026632915eb2ee9",
"assets/assets/images/green_coin.png": "2abf37e4e436e7a51c3bd4bdc5837e04",
"assets/assets/images/spectral_chain.png": "ce1fa1fd5da2daac30b555afaccd2d66",
"assets/assets/images/2.png": "e4c030fe25efa7969b584790729dab3c",
"assets/assets/images/explosion.png": "51f1ba827fb54a2f52c66cd52cd1c047",
"assets/assets/images/soul_fracture.png": "520ca9af10cdcde882c9cf4a67bd1c89",
"assets/assets/images/3.png": "a52fadbc91044b349c59788f8b05e476",
"assets/assets/images/1.png": "e955524b52a3402c220c40c36eedd4ee",
"assets/assets/images/0.png": "c3b0091cfcd13c30fad679c4bd9dd934",
"assets/assets/images/2-or.png": "e110349431a3e51fe535291f3db16151",
"assets/assets/audio/game_over.mp3": "39a1f880b5293497fe0323396cdfecaf",
"assets/assets/audio/mystical-winds.mp3": "133e391556b1f5d69c7b69f97d41a192",
"assets/assets/audio/soft_etheral.mp3": "889b2e0215c7a4aa4a0f5005ba56c649",
"assets/assets/fonts/LeagueGothic_Condensed-Regular.ttf": "d49c76a84fdd11b597acedcead2fc363",
"assets/assets/fonts/LeagueGothic_SemiCondensed-Regular.ttf": "2eca92563b47d99c07f8a1aef8787ff8",
"assets/assets/fonts/LeagueGothic-Regular-VariableFont_wdth.ttf": "09d2b8cbdd5401cdf22dde9ec147d5be",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
