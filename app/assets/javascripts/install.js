(function() {
	
var currentPanel = "style-install-unknown";

function getId() {
	return document.getElementById("style-id").innerHTML;
}
function toggleCode(event) {
	var showButton = document.getElementById("show-button");
	if (showButton.innerHTML == "Show CSS") {
		loadCode(function() {
			document.getElementById("view-code").style.display = "block";
			showButton.innerHTML = "Hide CSS";
		}, true);
	} else {
		hideCode();
	}
	event.preventDefault();
}
function hideCode() {
	var showButton = document.getElementById("show-button");
	document.getElementById("view-code").style.display = "none";
	showButton.innerHTML = "Show CSS";
}
function initShowCode() {
	var showButton = document.getElementById("show-button");
	addEvent(showButton, "click", toggleCode);
	showButton.style.display = "inline";

}

var currentOptions = null;
function loadCode(callback, promptOnIncomplete) {
	var codeElement = document.getElementById('stylish-code');
	var text;
	var options = getOptions(promptOnIncomplete);
	if (options == null) {
		return false;
	}
	var optionsString = toQueryString(options);
	if ("textContent" in codeElement)
		text = codeElement.textContent;
	else
		text = codeElement.innerText;
	if (text.length > 0 && optionsString == currentOptions) {
		if (callback) {
			callback();
		}
		return false;
	}
	var longOptions = optionsString.length > 2000;
	var xhr = new XMLHttpRequest();
	if (longOptions) {
		xhr.open('POST', '/styles/' + getId() + '.css', true);
		xhr.setRequestHeader("Content-type","application/x-www-form-urlencoded");
	} else {
		xhr.open('GET', '/styles/' + getId() + '.css' + (optionsString == "" ? "" : "?" + optionsString), true);
	}
	xhr.onreadystatechange = function(event) {
		if (xhr.readyState == 4) {
			if (xhr.status != 200) {
				document.body.style.cursor = "";
				alert('Sorry, an error occurred loading the code - status ' + xhr.status + '.');
				throw 'Sorry, an error occurred loading the code - status ' + xhr.status + '.';
			}
			if ("textContent" in codeElement)
				codeElement.textContent = xhr.responseText;
			else
				codeElement.innerText = xhr.responseText;
			currentOptions = optionsString;
			if (callback)
				callback();
			document.body.style.cursor = "";
		}
	}
	document.body.style.cursor = "wait";
	if (longOptions) {
		xhr.send(optionsString);
	} else {
		xhr.send(null);
	}
	return true;
}

function getOptions(promptOnIncomplete) {
	var styleOptions = document.getElementById("style-settings");
	if (!styleOptions) {
		return [];
	}
	// dropdown
	var selects = styleOptions.getElementsByTagName("select");
	var params = [];
	for (var i = 0; i < selects.length; i++) {
			params.push([selects[i].name, selects[i].value]);
	}
	var missingSettings = [];
	// color
	var inputs = styleOptions.querySelectorAll("input[type='text']");
	for (var i = 0; i < inputs.length; i++) {
			if (inputs[i].value == "") {
				missingSettings.push(inputs[i]);
			} else {
				params.push([inputs[i].name, inputs[i].value]);
			}
	}
	// image
	inputs = styleOptions.querySelectorAll("input[type='radio']:checked");
	for (var i = 0; i < inputs.length; i++) {
		switch (inputs[i].value) {
			case "user-url":
				var idParts = inputs[i].id.split("-");
				var id = "option-user-url-" + idParts[idParts.length - 1];
				var userInput = document.getElementById(id);
				if (userInput.value == '') {
					missingSettings.push(userInput.parentNode);
				} else {
					params.push([inputs[i].name, userInput.value]);
				}
				break;
			case "user-upload":
				var idParts = inputs[i].id.split("-");
				var id = "option-user-upload-" + idParts[idParts.length - 1];
				var userInput = document.getElementById(id);
				if (!userInput.uploadedData) {
					missingSettings.push(userInput.parentNode);
				} else {
					params.push([inputs[i].name, userInput.uploadedData]);
				}
				break;
			default:
				params.push([inputs[i].name, inputs[i].value]);
				break;
		}
	}

	if (missingSettings.length > 0) {
		if (promptOnIncomplete) {
			alert("Choose a value for every setting first.");
			//settings[i].input.parentNode.scrollIntoView();
			missingSettings[0].scrollIntoView();
			/*setTimeout(function () {
				for (var i = 0; i < missingSettings.length; i++) {
					new Effect.Highlight(missingSettings[i], {endcolor: "#7CCD7C"});
				}
			}, 500);*/
		}
		return null;
	}

	return params;
}

function toQueryString(optionsArray) {
	return optionsArray.map(function(a) {
		return encodeURIComponent(a[0]) + "=" + encodeURIComponent(a[1]);
	}).join("&");
}

function loadUpload(input) {
	var oFile = input.files[0];  
	if (input.files.length === 0) {
		input.uploadedData = null;
	}
	var oFReader = new FileReader()
	oFReader.onload = function (oFREvent) {  
		input.uploadedData = oFREvent.target.result;
	}; 
	oFReader.readAsDataURL(oFile);
}

//we fire these to tell stylish what to do
function stylishInstall(event) {
	loadCode(stylishInstall2, true);
}
function stylishInstall2() {
	updateLinkThenFire("stylish-update-url", "stylishInstall");
}
function stylishInstallIE(event) {
	updateLinkThenFire("stylish-update-url", "stylishInstall");
}

function updateLinkThenFire(linkRel, eventName) {
	var options = getOptions(true);
	if (options != null) {
		var link = document.querySelector("link[rel='" + linkRel + "']");
		if (link) {
			var url = link.href.split("?")[0];
			link.setAttribute("href", url + "?" + toQueryString(options));
		}
		fireCustomEvent(eventName);
	}
}

function stylishInstallChrome(event) {
	updateLinkThenFire("stylish-code-chrome", "stylishInstallChrome");
}
function stylishUpdateChrome(event) {
	updateLinkThenFire("stylish-code-chrome", "stylishUpdateChrome");
}
function stylishInstallOpera(event) {
	updateLinkThenFire("stylish-code-opera", "stylishInstallOpera");
}
function stylishUpdateOpera(event) {
	updateLinkThenFire("stylish-code-opera", "stylishUpdateOpera");
}

function stylishUpdate() {
	loadCode(stylishUpdate2, true);
}
function stylishUpdate2() {
	var stylishEvent = document.createEvent("Events");
	updateLinkThenFire("stylish-update-url", "stylishUpdate");
}

function fireCustomEvent(name) {
	if (document.createEvent) {
		var stylishEvent = document.createEvent("Events");
		stylishEvent.initEvent(name, false, false, window, null);
		document.dispatchEvent(stylishEvent);
	} else {
		var communicationElement = document.getElementById("stylish-event-element");
		communicationElement.setAttribute("stylish-data", name);
		communicationElement.click();
	}
};

var stylishActivatedPanel = null;
function switchToPanel(panelId) {
	var newPanel = document.getElementById(panelId);
	if (!newPanel) {
		return false;
	}
	document.getElementById(currentPanel).style.display = "none";
	newPanel.style.display = "";
	currentPanel = panelId;
	return true;
}

function switchBrowserValue(value) {
	var select = document.getElementById("switch-browser");
	if (select) {
		var options = select.getElementsByTagName("option");
		for (var i = 0; i < options.length; i++) {
			if (options[i].value == value) {
				options[i].selected = true;
				return;
			}
		}
	}
}

//stylish will fire this after the user installs or updates
function styleInstalled() {
	if (BrowserDetect.browser == "Explorer") {
		genericStyleInstalled("stylish-installed-style-installed-ie");
	} else {
		genericStyleInstalled("stylish-installed-style-installed");
	}
}
function styleInstalledChrome() {
	genericStyleInstalled("stylish-installed-style-installed-chrome");
}
function styleInstalledOpera() {
	genericStyleInstalled("stylish-installed-style-installed-opera");
}
function genericStyleInstalled(panel) {
	switchToPanel(panel);
	addAdToInstallBox(panel);
	stylishActivatedPanel = panel;
}

function userStyleInstall(event) {
	var link = event.target;
	var options = getOptions(true);
	if (options == null) {
		event.preventDefault();
		return;
	}
	var baseUrl = link.href.split("?")[0];
	setTimeout(function() {
		addAdToInstallBox(link.parentNode.parentNode.id);
	}, 3000);
	// if it's too long, do a post instead
	var optionsString = toQueryString(options);
	if (optionsString.length > 2000) {
		setTimeout(function() {
			fakeFormSubmit(baseUrl, options);
		}, 250);
		event.preventDefault();
		return;
	}
	// add parameters to the url, but we need to end with .user.js
	link.href = baseUrl + (optionsString == "" ? "" : "?" + optionsString + "&.user.js");
}

function fakeFormSubmit(url, options) {
	// get the POST url - /styles/userjs/ID. this will avoid the GM trigger as it does not support POST params
	document.body.style.cursor = "wait";
	urlParts = url.split("/");
	url = "/styles/userjs/" + urlParts[urlParts.length - 2];
	var form = document.createElement("form");
	form.style.display = "none";
	form.setAttribute("method", "POST");
	form.setAttribute("action", url);
	for (var i = 0; i < options.length; i++) {
		var input = document.createElement("input");
		input.name = options[i][0];
		input.value = options[i][1];
		form.appendChild(input);
	}
	var submit = document.createElement("input");
	submit.type = "submit";
	form.appendChild(submit);
	document.body.appendChild(form);
	submit.click();
	document.body.style.cursor = "";
}

function updateNonStylishInstallLinks() {
	var options = getOptions(false);
	if (options == null) {
		return;
	}
	var optionsString = toQueryString(options);
	var links = document.querySelectorAll(".alternate-install");
	for (var i = 0; i < links.length; i++) {
		var currentUrl = links[i].getAttribute("href");
		var currentUrlParts = currentUrl.split("?");
		if (currentUrlParts.length > 1) {
			currentUrl = currentUrlParts[0];
		}
		links[i].setAttribute("href", currentUrl + ((optionsString == "" || optionsString.length > 2000) ? "" : "?" + optionsString));
	}
}

function addAdToInstallBox(installBoxId) {
	var pia = document.getElementById("post-install-ad");
	var installBox = document.getElementById(installBoxId);
	if (pia.className == "afterdownload-ad") {
		installBox.appendChild(pia);
		pia.style.display = "";
	} else {
		var placeholder = document.createElement("div");
		// matches ad size, plus 12 on height for padding
		placeholder.style.width = "300px";
		placeholder.style.height = "262px";
		installBox.appendChild(placeholder);
		pia.style.top = placeholder.offsetTop + "px";
		pia.style.left = placeholder.offsetLeft + "px";
		pia.style.position = "absolute";
		pia.style.display = "block";
	}
}

//stylish will fire these on load
function styleCanBeInstalled(event) {
	if (!event && BrowserDetect.browser == "Explorer") {
		genericStyleCanBeInstalled("stylish-installed-style-not-installed-ie");
	} else {
		genericStyleCanBeInstalled("stylish-installed-style-not-installed");
	}
}
function styleCanBeInstalledChrome(event) {
	genericStyleCanBeInstalled("stylish-installed-style-not-installed-chrome");
}
function styleCanBeInstalledOpera(event) {
	genericStyleCanBeInstalled("stylish-installed-style-not-installed-opera");
}
function genericStyleCanBeInstalled(panel) {
	// Stylish can fire this even when we're not a style page, so guard for that.
	if (switchToPanel(panel)) {
		stylishActivatedPanel = panel;
	}
}

function styleAlreadyInstalled(event) {
	// assuming anything with settings can be updated if already installed
	if (styleHasSettings()) {
		styleCanBeUpdated(event);
	} else {
		styleInstalled();
	}
}
function styleAlreadyInstalledChrome() {
	// assuming anything with settings can be updated if already installed
	if (styleHasSettings()) {
		styleCanBeUpdatedChrome(event);
	} else {
		styleInstalledChrome();
	}
}
function styleAlreadyInstalledOpera() {
	styleInstalledOpera();
}

function styleCanBeUpdated(event) {
	genericStyleCanBeUpdated("stylish-installed-style-needs-update", "detail" in event ? event.detail : null);
}
function styleCanBeUpdatedChrome(event) {
	genericStyleCanBeUpdated("stylish-installed-style-needs-update-chrome", "detail" in event ? event.detail : null);
}
function styleCanBeUpdatedOpera() {
	genericStyleCanBeUpdated("stylish-installed-style-needs-update-opera", null);
}
function genericStyleCanBeUpdated(panel, detail) {
	switchToPanel(panel);
	stylishActivatedPanel = panel;
	if (detail && "updateUrl" in detail) {
		var params = parseQueryString(detail.updateUrl);
		for (var i in params) {
			setFormValue(i, params[i]);
		}
	}
}

function setFormValue(name, value) {
	var els = document.getElementsByName(name);
	if (els.length == 0) {
		return;
	}
	var firstEl = els.item(0);
	if (firstEl.nodeName.toLowerCase() == "input") {
		if (firstEl.type == "text") {
			firstEl.value = value;
			return;
		}
		if (firstEl.type == "radio") {
			for (var i = 0; i < els.length; i++) {
				if (els.item(i).value == value) {
					els.item(i).checked = true;
					return;
				}
				if (els.item(i).hasAttribute("data-related-input")) {
					els.item(i).checked = true;
					document.getElementById(els.item(i).getAttribute("data-related-input")).value = value;
					return;
				}
			}
		}
		return;
	}
	if (firstEl.nodeName.toLowerCase() == "select") {
		firstEl.value = value;
	}
}

function parseQueryString(url) {
	var paramMap = {};
	var urlParts = url.split("?");
	if (urlParts.length != 2) {
		return paramMap;
	}
	var queryString = urlParts[1];
	var paramStrings = queryString.split("&");
	for (var i = 0; i < paramStrings.length; i++) {
		var paramParts = paramStrings[i].split("=");
		if (paramParts.length == 2) {
			paramMap[decodeURIComponent(paramParts[0])] = decodeURIComponent(paramParts[1]);
		}
	}
	return paramMap;
}

function styleHasSettings() {
	return document.getElementById("style-settings") != null;
}

function initInstall() {
	// make sure Stylish didn't already change this
	if (currentPanel != "style-install-unknown") {
		return;
	}
	var switchBrowser = document.getElementById("switch-browser");
	if (switchBrowser) {
		switchBrowser.parentNode.style.display = "";
	}
	switch (BrowserDetect.browser) {
		case "Chrome":
			// mobile chrome can't do this yet
			if (navigator.userAgent.indexOf("Android") > -1) {
				switchToPanel("style-install-mobile-chrome-android");
				switchBrowserValue("mobilechromeandroid");
				break;
			}
			switchToPanel("style-install-chrome");
			switchBrowserValue("chrome");
			break;
		case "Opera":
			switchToPanel("style-install-opera");
			switchBrowserValue("opera");
			break;
		case "Safari":
			switchToPanel("style-install-safari");
			switchBrowserValue("safari");
			break;
		case "Explorer":
			switchToPanel("style-install-ie");
			switchBrowserValue("ie");
			break;
		case "Mozilla":
			// this thing thinks safari on android is mozilla
			if (navigator.userAgent.indexOf("Safari") > -1 && navigator.userAgent.indexOf("Android") > -1) {
				switchToPanel("style-install-mobile-safari-android");
				switchBrowserValue("mobilesafariandroid");
				break;
			}
			// if not, fallthrough
		case "Firefox":
		case "Netscape":
			switchToPanel("style-install-mozilla-no-stylish");
			switchBrowserValue("mozilla");
			break;
		default:
			switchBrowserValue("other");
	}
}

function addCustomEventListener(name, f) {
	if (document.addEventListener) {
		document.addEventListener(name, f, false);
	} 
	else {
		if (listenerMappings == null) {
			// The right way to do it, but it doesn't work... It will just call this directly
			//document.getElementById("stylish-event-element").attachEvent("onclick", handleCustomEvent);
			listenerMappings = {};
		}
		listenerMappings[name] = f;
	}
}

var listenerMappings = null;
function handleCustomEvent() {
	var communicationElement = document.getElementById("stylish-event-element");
	var f = listenerMappings[communicationElement.getAttribute("stylish-data")];
	if (f)
		f();
}

function addEvent(element, name, f) {
	if (element.addEventListener) {
		element.addEventListener(name, f, false);
	} else {
		element.attachEvent("on" + name, f);
	}
}

function addClickEvent(id, fn) {
	var el = document.getElementById(id);
	if (!el)
		return;
	el.addEventListener("click", fn, false);
}

function addStylishListeners() {
	addCustomEventListener("styleInstalled", styleInstalled);
	addCustomEventListener("styleInstalledChrome", styleInstalledChrome);
	addCustomEventListener("styleInstalledOpera", styleInstalledOpera);
	addCustomEventListener("styleAlreadyInstalled", styleAlreadyInstalled);
	addCustomEventListener("styleAlreadyInstalledChrome", styleAlreadyInstalledChrome);
	addCustomEventListener("styleAlreadyInstalledOpera", styleAlreadyInstalledOpera);
	addCustomEventListener("styleCanBeInstalled", styleCanBeInstalled);
	addCustomEventListener("styleCanBeInstalledChrome", styleCanBeInstalledChrome);
	addCustomEventListener("styleCanBeInstalledOpera", styleCanBeInstalledOpera);
	addCustomEventListener("styleCanBeUpdated", styleCanBeUpdated);
	addCustomEventListener("styleCanBeUpdatedChrome", styleCanBeUpdatedChrome);
	addCustomEventListener("styleCanBeUpdatedOpera", styleCanBeUpdatedOpera);
	addCustomEventListener("styleLoadCode", function() {
		if (!loadCode(codeLoaded, false)) {
			codeCantBeLoaded();
		}
	});
	// defined in standard_layout.html.erb, see note there.
	stopRecordingEvents();
}

function addEvents() {
	addClickEvent("stylish-installed-style-not-installed-chrome", stylishInstallChrome);
	addClickEvent("stylish-installed-style-needs-update", stylishUpdate);
	addClickEvent("stylish-installed-style-needs-update-chrome", stylishUpdateChrome);
	addClickEvent("stylish-installed-style-needs-update-opera", stylishUpdateOpera);
	addClickEvent("stylish-installed-style-not-installed", stylishInstall);
	addClickEvent("stylish-installed-style-not-installed-ie", stylishInstallIE);
	addClickEvent("mozilla-user-style-install", userStyleInstall);
	addClickEvent("ie-user-style-install", userStyleInstall);
	addClickEvent("opera-css-install-both", userStyleInstall);
	addClickEvent("opera-userjs-install-both", userStyleInstall);
	addClickEvent("opera-css-install", userStyleInstall);
	addClickEvent("opera-userjs-install", userStyleInstall);
	addClickEvent("newopera-userjs-install", userStyleInstall);
	addClickEvent("stylish-installed-style-not-installed-opera", stylishInstallOpera);
	addClickEvent("chrome-userjs-install", userStyleInstall);
	
	addClickEvent("install-stylish-chrome", installStylishChrome);
	
	var optionValues = document.querySelectorAll('.style-setting-option');
	for (var i = 0; i < optionValues.length; i++) {
		optionValues[i].addEventListener("change", updateOption, false);
	}
	
	var optionUserUrls = document.querySelectorAll(".option-user-url");
	for (var i = 0; i < optionUserUrls.length; i++) {
		optionUserUrls[i].addEventListener("change", updateUserUrlOption, false);
	}

	var optionUserUploads = document.querySelectorAll(".option-user-upload");
	for (var i = 0; i < optionUserUploads.length; i++) {
		optionUserUploads[i].addEventListener("change", updateUserUploadOption, false);
	}
}

function updateOption(event) {
	hideCode();
	updateNonStylishInstallLinks();
}

function updateUserUrlOption(event) {
	var idParts = event.target.id.split("-");
	var id = idParts[idParts.length - 1];
	document.getElementById("option-url-choice-" + id).checked = true;
	updateOption(event);
}

function updateUserUploadOption(event) {
	var idParts = event.target.id.split("-");
	var id = idParts[idParts.length - 1];
	loadUpload(event.target);
	document.getElementById("option-upload-choice-" + id).checked = true;
	updateOption(event);
}

function installStylishChrome(event) {
	 chrome.webstore.install(event.target.href, function(){setTimeout(function(){location.reload()}, 3000)});
	 event.preventDefault();
}

function codeLoaded() {
	var stylishEvent = document.createEvent("Events");
	stylishEvent.initEvent("stylishCodeLoaded", false, false, window, null);
	document.dispatchEvent(stylishEvent);
}

function codeCantBeLoaded() {
	var stylishEvent = document.createEvent("Events");
	stylishEvent.initEvent("stylishCodeCantBeLoaded", false, false, window, null);
	document.dispatchEvent(stylishEvent);
}

function switchBrowser(select) {
	switch (select.value) {
		case "ie":
			if (stylishActivatedPanel == "stylish-installed-style-installed-ie" || stylishActivatedPanel == "stylish-installed-style-not-installed-ie") {
				switchToPanel(stylishActivatedPanel);
			} else {
				switchToPanel("style-install-ie");
			}
			break;
		case "mozilla":
			if (stylishActivatedPanel == "stylish-installed-style-installed" || stylishActivatedPanel == "stylish-installed-style-not-installed" || stylishActivatedPanel == "stylish-installed-style-needs-update") {
				switchToPanel(stylishActivatedPanel);
			} else {
				switchToPanel("style-install-mozilla-no-stylish");
			}
			break;
		case "opera":
			if (stylishActivatedPanel == "stylish-installed-style-installed-opera" || stylishActivatedPanel == "stylish-installed-style-not-installed-opera" || stylishActivatedPanel == "stylish-installed-style-needs-update-opera") {
				switchToPanel(stylishActivatedPanel);
			} else {
				switchToPanel("style-install-opera");
			}
			break;
		case "chrome":
			if (stylishActivatedPanel == "stylish-installed-style-installed-chrome" || stylishActivatedPanel == "stylish-installed-style-not-installed-chrome" || stylishActivatedPanel == "stylish-installed-style-needs-update-chrome") {
				switchToPanel(stylishActivatedPanel);
			} else {
				switchToPanel("style-install-chrome");
			}
			break;
		case "mobilesafariandroid":
			switchToPanel("style-install-mobile-safari-android");
			break;
		case "mobilechromeandroid":
			switchToPanel("style-install-mobile-chrome-android");
			break;
		case "other":
			switchToPanel("style-install-unknown");
			break;
	}
}

function loadSettingsBasedOnUrl() {
	var params = parseQueryString(location.href);
	for (var i in params) {
		setFormValue(i, params[i]);
	}
}

function init() {
	if (document.getElementById("show-button")) {
		initShowCode();
		// update these links with the default values
		updateNonStylishInstallLinks();
		initInstall();
		addEvents();
		loadSettingsBasedOnUrl();
	}
}

// run this immediately to prevent a race between Stylish emitting this event and this script adding a listener
addStylishListeners();

if (document.readyState == "loading") {
	window.addEventListener("DOMContentLoaded", init, false);
} else {
	init();
}

})();
