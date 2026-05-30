+++
title = "Email Signature"
description = "The official IT Help San Diego email signature — live preview and install instructions for Apple Mail."
path = "signature"
render = true

[extra]
stylesheets = ["css/signature.css"]
skip_author = true
skip_image = true
toc = false
+++

<div class="sig-page">

<p class="sig-page__intro">The official IT Help San Diego email signature. Preview it below, then open the raw version to copy and paste it into Mail. Edit <code>static/ithelp-logo-sig-research.html</code> to adjust it over time.</p>

<div class="sig-preview">
<table cellpadding="0" cellspacing="0" border="0" width="560" class="sig-table">
<tbody>
<tr><td height="3" class="sig-gold-bar">&nbsp;</td></tr>
<tr>
<td class="sig-body-cell">
<table cellpadding="0" cellspacing="0" border="0" width="100%" class="sig-inner-table">
<tbody>
<tr>
<td width="142" valign="middle" class="sig-avatar-cell">
<a href="https://dnstool.it-help.tech" class="sig-avatar-link"><img src="/images/owl-signature.png" width="130" height="130" alt="Owl of Athena" class="sig-avatar-img" /></a>
</td>
<td width="1" class="sig-divider-cell">&nbsp;</td>
<td valign="middle" class="sig-content-cell">
<div class="sig-brand"><span class="sig-brand-gold">IT</span><span class="sig-brand-red">+</span><span class="sig-brand-gold">HELP</span>&nbsp;<span class="sig-brand-location">SAN DIEGO</span></div>
<div class="sig-tagline">IT research that solves.</div>
<div class="sig-details">
<strong class="sig-name">Carey Balboa</strong>&nbsp;<span class="sig-muted">|</span>&nbsp;<span class="sig-role">Director of Technology</span><br>
<span class="sig-muted">ORCID:&nbsp;<a href="https://orcid.org/0009-0000-5237-9065" class="sig-link">0009-0000-5237-9065</a></span><br>
<span class="sig-muted">Independent DNS Security Researcher</span><br>
<span class="sig-muted">Research artifact:&nbsp;<a href="https://doi.org/10.5281/zenodo.19468134" class="sig-link">DNS Tool (DOI: 10.5281/zenodo.19468134)</a></span><br>
<span class="sig-muted">Methodology:&nbsp;<a href="https://dnstool.it-help.tech/docs/dns-tool-methodology.pdf" class="sig-link">dns-tool-methodology.pdf</a></span><br>
<span class="sig-muted"><a href="tel:+16198535008" class="sig-link">+1 (619) 853-5008</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="mailto:carey.balboa@it-help.tech" class="sig-link">carey.balboa@it-help.tech</a></span>
</div>
<div class="sig-gap">&nbsp;</div>
<div class="sig-address">
<strong class="sig-company">IT Help San Diego Inc.</strong><br>
888 Prospect Street, Suite 200<br>
La Jolla, CA 92037<br>
<a href="https://www.it-help.tech" class="sig-link">www.it-help.tech</a>
<span class="sig-sep">&nbsp;|&nbsp;</span>
<a href="https://dnstool.it-help.tech" class="sig-link">DNS Security Tool</a>
</div>
</td>
</tr>
</tbody>
</table>
</td>
</tr>
<tr><td height="1" class="sig-bottom-bar">&nbsp;</td></tr>
</tbody>
</table>
</div>

<div class="sig-actions">
<a href="/ithelp-logo-sig-research.html" target="_blank" rel="noopener noreferrer" class="sig-btn sig-btn--primary">Open the signature to copy <span class="sig-btn__ext" aria-hidden="true">↗</span></a>
</div>

<section class="sig-section">
<h2 class="sig-section__title">Installation — Apple Mail</h2>
<ol>
<li>Open <a href="/ithelp-logo-sig-research.html" target="_blank" rel="noopener noreferrer">the raw signature</a> in <strong>Safari</strong> (not Chrome — Safari preserves rich-text copy fidelity for Mail).</li>
<li>Press <kbd>⌘A</kbd> (Select All), then <kbd>⌘C</kbd> (Copy).</li>
<li>In Mail, go to <strong>Settings → Signatures</strong>. Create a new signature (or edit an existing one).</li>
<li>Click in the signature edit area, press <kbd>⌘A</kbd> then <kbd>⌘V</kbd> (Paste).</li>
<li>The dark background is embedded as <code>bgcolor</code> + inline <code>background-color</code> on every cell, so it persists when sent.</li>
</ol>
</section>

<section class="sig-section">
<h2 class="sig-section__title">Design notes</h2>
<ul>
<li><strong>Background persistence</strong>: every <code>&lt;td&gt;</code> carries both CSS <code>background-color:#111827</code> and the legacy <code>bgcolor="#111827"</code> attribute. Gmail honors only CSS, Outlook honors only <code>bgcolor</code>, and Apple Mail honors both.</li>
<li><strong>Gold accent lines</strong>: a 3px gradient-gold top rule and a 1px bottom rule create the embossed-letterhead framing. The vertical divider uses the same muted gold at 25% opacity.</li>
<li><strong>Typography</strong>: the system font stack (<code>-apple-system</code>) ensures native rendering. Gold (<code>#c8a878</code>) for links, light gray (<code>#d1d5db</code> / <code>#9ca3af</code>) for text hierarchy.</li>
</ul>
</section>

</div>
