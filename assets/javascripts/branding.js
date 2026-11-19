/*
 * Branding – setzt das Logo vor den Seitentitel im Kopf.
 *
 * Adresse aus <meta name="branding-logo"> (vom Plugin ausgegeben).
 * Themes, die das Logo selbst darstellen, setzen data-branding-logo="theme"
 * an <html> – dann tut dieses Script nichts.
 */
(function () {
  'use strict';

  // Ziel des Logos: <meta name="branding-logo-link"> (Admin-Vorgabe bzw.
  // Benutzereinstellung), sonst Redmines Link zur Hauptseite
  function linkTarget() {
    var meta = document.querySelector('meta[name="branding-logo-link"]');
    if (meta && meta.content) {
      return { href: meta.content, label: meta.getAttribute('data-label') || '' };
    }
    var home = document.querySelector('#top-menu a.home');
    return { href: home ? home.href : '/', label: home ? home.textContent.trim() : '' };
  }

  function createLogo(url, className) {
    var target = linkTarget();
    var link = document.createElement('a');
    link.className = className;
    link.href = target.href;
    if (target.label) {
      link.setAttribute('aria-label', target.label);
    }

    var image = document.createElement('img');
    image.src = url;
    image.alt = '';
    image.addEventListener('error', function () {
      link.remove();
    });
    link.appendChild(image);
    return link;
  }

  // Desktop: im Seitentitel vor Brotkrumen/Projektnamen.
  // Mobil blendet Redmine den Seitentitel aus; dort steht ein zweites Logo
  // vor der Projektauswahl (#quick-search). branding.css zeigt je Breite eins.
  function insertLogo() {
    if (document.documentElement.getAttribute('data-branding-logo') === 'theme') {
      return;
    }

    var meta = document.querySelector('meta[name="branding-logo"]');
    var header = document.getElementById('header');
    if (!meta || !meta.content || !header || header.querySelector('.branding-logo')) {
      return;
    }

    var title = header.querySelector('h1');
    if (title) {
      title.insertBefore(createLogo(meta.content, 'branding-logo'), title.firstChild);
    } else {
      header.insertBefore(createLogo(meta.content, 'branding-logo'), header.firstChild);
    }

    var quickSearch = document.getElementById('quick-search');
    if (quickSearch) {
      quickSearch.insertBefore(createLogo(meta.content, 'branding-logo branding-logo-mobile'), quickSearch.firstChild);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', insertLogo);
  } else {
    insertLogo();
  }
})();
