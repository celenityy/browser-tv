// Inspired by https://searchfox.org/firefox-main/source/toolkit/components/normandy/content/AboutPages.sys.mjs

import { XPCOMUtils } from "resource://gre/modules/XPCOMUtils.sys.mjs";

const lazy = {};

/**
 * Class for managing about: pages provided by Browser TV.
 *
 * @implements nsIFactory
 * @implements nsIAboutModule
 */
class AboutPage {
  constructor({ chromeUrl, aboutHost, classID, description, uriFlags }) {
    this.chromeUrl = chromeUrl;
    this.aboutHost = aboutHost;
    this.classID = Components.ID(classID);
    this.description = description;
    this.uriFlags = uriFlags;
  }

  getURIFlags() {
    return this.uriFlags;
  }

  newChannel(uri, loadInfo) {
    const newURI = Services.io.newURI(this.chromeUrl);
    const channel = Services.io.newChannelFromURIWithLoadInfo(newURI, loadInfo);
    channel.originalURI = uri;

    if (this.uriFlags & Ci.nsIAboutModule.URI_SAFE_FOR_UNTRUSTED_CONTENT) {
      const principal = Services.scriptSecurityManager.createContentPrincipal(
        uri,
        {}
      );
      channel.owner = principal;
    }
    return channel;
  }
}
AboutPage.prototype.QueryInterface = ChromeUtils.generateQI(["nsIAboutModule"]);

/**
 * The module exported by this file.
 */
export let BrowserTVAboutPages = {};

ChromeUtils.defineLazyGetter(BrowserTVAboutPages, "aboutPolicies", () => {
  const aboutPolicies = new AboutPage({
    chromeUrl: "chrome://browser/content/policies/aboutPolicies.html",
    aboutHost: "policies",
    classID: "{b3ac3a21-fb4b-4013-9bcb-bbb4ae1ea861}",
    description: "about:policies",
    uriFlags:
      Ci.nsIAboutModule.ALLOW_SCRIPT |
      Ci.nsIAboutModule.IS_SECURE_CHROME_UI,
  });
  return aboutPolicies;
});

ChromeUtils.defineLazyGetter(BrowserTVAboutPages, "aboutRobots", () => {
  const aboutRobots = new AboutPage({
    chromeUrl: "chrome://browser/content/aboutRobots.xhtml",
    aboutHost: "robots",
    classID: "{057bb874-aabf-4b9a-a43e-3440c3e4bfa2}",
    description: "about:robots",
    uriFlags:
      Ci.nsIAboutModule.ALLOW_SCRIPT |
      Ci.nsIAboutModule.URI_SAFE_FOR_UNTRUSTED_CONTENT,
  });
  return aboutRobots;
});

export function AboutPolicies() {
  return BrowserTVAboutPages.aboutPolicies;
}

export function AboutRobots() {
  return BrowserTVAboutPages.aboutRobots;
}
