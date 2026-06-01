globalThis.addEventListener('DOMContentLoaded', () => {
  const logo = document.querySelector('.logo-container');
  if (!logo) {
    return;
  }

  initLogoTilt(logo);
  scheduleConstellationInit(logo);
});

function scheduleConstellationInit(logo) {
  const start = () => {
    initConstellation(logo);
  };

  if (typeof globalThis.requestIdleCallback === 'function') {
    globalThis.requestIdleCallback(start, { timeout: 1400 });
    return;
  }

  globalThis.setTimeout(start, 180);
}

function initLogoTilt(logo) {
  const reducedMotion =
    typeof globalThis.matchMedia === 'function' &&
    globalThis.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reducedMotion || typeof logo.animate !== 'function') {
    return;
  }

  let tiltAnim;
  const setTilt = (transform) => {
    if (tiltAnim) {
      tiltAnim.cancel();
    }
    tiltAnim = logo.animate([{ transform }], {
      duration: 100,
      fill: 'forwards',
      easing: 'ease-out',
    });
  };

  logo.addEventListener('mousemove', (event) => {
    const rect = logo.getBoundingClientRect();
    const x = (event.clientX - rect.left) / rect.width - 0.5;
    const y = (event.clientY - rect.top) / rect.height - 0.5;
    setTilt(`perspective(1000px) rotateY(${x * 10}deg) rotateX(${-y * 10}deg)`);
  });

  logo.addEventListener('mouseleave', () => {
    setTilt('perspective(1000px) rotateY(0) rotateX(0)');
  });
}

function initConstellation(logo) {
  const canvas = logo.querySelector('.logo-constellation');
  if (!canvas || typeof canvas.getContext !== 'function') {
    return;
  }

  const context = canvas.getContext('2d', { alpha: true, desynchronized: true });
  if (!context) {
    return;
  }

  const state = createConstellationState(
    logo,
    canvas,
    context,
    getReducedMotionQuery()
  );

  state.renderFrame = (timestamp) => {
    renderConstellationFrame(timestamp, state);
  };

  bindPointerEvents(state);
  bindVisibilityEvents(state);
  bindMotionPreferenceEvents(state);
  bindResizeEvents(state);
  bindIntersectionEvents(state);

  resizeConstellation(state);
  applyMotionPreference(state);
}

function getReducedMotionQuery() {
  if (typeof globalThis.matchMedia !== 'function') {
    return null;
  }
  return globalThis.matchMedia('(prefers-reduced-motion: reduce)');
}

function createConstellationState(logo, canvas, context, motionQuery) {
  return {
    logo,
    canvas,
    context,
    motionQuery,
    reducedMotion: motionQuery ? motionQuery.matches : false,
    width: 1,
    height: 1,
    dpr: 1,
    running: false,
    inView: true,
    frameHandle: 0,
    previousTimestamp: 0,
    lastRenderTimestamp: 0,
    targetFrameInterval: 0,
    pointerTargetX: 0,
    pointerTargetY: 0,
    pointerX: 0,
    pointerY: 0,
    logoRect: null,
    touchViewport: isTouchViewport(),
    touchDarkBoost: isTouchDarkMode(),
    nodes: [],
    renderFrame: null,
  };
}

function nodeCountForArea(area) {
  if (area <= 90000) {
    return 20;
  }
  if (area <= 160000) {
    return 24;
  }
  return 28;
}

const PHI = (1 + Math.sqrt(5)) / 2;
const GOLDEN_ANGLE = Math.PI * (3 - Math.sqrt(5));
const INVERSE_PHI = 1 / PHI;
const RANDOM_POOL_SIZE = 128;
let randomPool = null;
let randomPoolIndex = RANDOM_POOL_SIZE;

function matchesMediaQuery(query) {
  return typeof globalThis.matchMedia === 'function' && globalThis.matchMedia(query).matches;
}

function isTouchViewport() {
  const viewportWidth = Math.min(
    globalThis.innerWidth || Number.POSITIVE_INFINITY,
    globalThis.screen?.width || Number.POSITIVE_INFINITY
  );
  return viewportWidth <= 900 || matchesMediaQuery('(pointer: coarse)');
}

function isTouchDarkMode() {
  return isTouchViewport() && !document.documentElement.classList.contains('switch');
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

// Safari/WebKit refuses to allocate canvas backing stores larger than
// 16384 px on a side or ~268M total pixels; on overflow the canvas
// silently fails to render. Cap dimensions and area to safe limits and
// scale the device-pixel ratio down accordingly so drawings stay aligned.
const MAX_CANVAS_DIM = 8192;
const MAX_CANVAS_AREA = 16777216;
function clampCanvasDpr(cssWidth, cssHeight, dpr) {
  if (cssWidth <= 0 || cssHeight <= 0 || dpr <= 0) {
    return dpr;
  }
  let pxW = cssWidth * dpr;
  let pxH = cssHeight * dpr;
  let scale = 1;
  const dimScale = Math.min(1, MAX_CANVAS_DIM / Math.max(pxW, pxH));
  scale *= dimScale;
  pxW *= dimScale;
  pxH *= dimScale;
  const area = pxW * pxH;
  if (area > MAX_CANVAS_AREA) {
    scale *= Math.sqrt(MAX_CANVAS_AREA / area);
  }
  return dpr * scale;
}

function randomUnit() {
  if (globalThis.crypto?.getRandomValues) {
    if (!randomPool || randomPoolIndex >= RANDOM_POOL_SIZE) {
      randomPool = new Uint32Array(RANDOM_POOL_SIZE);
      globalThis.crypto.getRandomValues(randomPool);
      randomPoolIndex = 0;
    }

    const value = randomPool[randomPoolIndex];
    randomPoolIndex += 1;
    return value / 4294967296;
  }

  return 0.5;
}

function resolveTargetFrameInterval(touchViewport, touchDarkBoost) {
  if (touchDarkBoost) {
    return 34;
  }
  if (touchViewport) {
    return 30;
  }
  return 0;
}

function seededSpiralPoint(index, count, width, height) {
  const centerX = width * 0.5;
  const centerY = height * 0.5;
  const maxRadius = Math.hypot(width, height) * (0.45 + INVERSE_PHI * 0.15);

  const normalized = (index + 0.5) / count;
  const radial = Math.sqrt(normalized) * maxRadius;
  const angle = index * GOLDEN_ANGLE;

  const jitterRadius = (randomUnit() - 0.5) * maxRadius * 0.07;
  const jitterAngle = (randomUnit() - 0.5) * 0.28;
  const offsetX = Math.cos(angle + jitterAngle) * (radial + jitterRadius);
  const offsetY = Math.sin(angle + jitterAngle) * (radial + jitterRadius);

  return {
    x: clamp(centerX + offsetX, 0, width),
    y: clamp(centerY + offsetY, 0, height),
    angle,
  };
}

function createNodes(count, width, height) {
  const nodes = [];
  for (let index = 0; index < count; index += 1) {
    const seed = seededSpiralPoint(index, count, width, height);
    const driftAngle = seed.angle + Math.PI * 0.5 + (randomUnit() - 0.5) * 1.15;
    const speed = 0.048 + randomUnit() * 0.108;
    nodes.push({
      x: seed.x,
      y: seed.y,
      vx: Math.cos(driftAngle) * speed,
      vy: Math.sin(driftAngle) * speed,
      depth: 0.35 + randomUnit() * 0.85,
      radius: 0.75 + randomUnit() * 1.25,
      gold: randomUnit() < 0.3,
      ox: 0,
      oy: 0,
    });
  }
  return nodes;
}

function clampNodes(nodes, width, height) {
  for (const node of nodes) {
    node.x = clamp(node.x, 0, width);
    node.y = clamp(node.y, 0, height);
  }
}

function resizeConstellation(state) {
  state.logoRect = state.logo.getBoundingClientRect();
  const rect = state.canvas.getBoundingClientRect();
  state.width = Math.max(1, Math.floor(rect.width));
  state.height = Math.max(1, Math.floor(rect.height));
  state.touchViewport = isTouchViewport();
  state.touchDarkBoost = isTouchDarkMode();
  state.targetFrameInterval = resolveTargetFrameInterval(
    state.touchViewport,
    state.touchDarkBoost
  );
  state.dpr = state.touchViewport
    ? Math.min(globalThis.devicePixelRatio || 1, 1.5)
    : Math.min(globalThis.devicePixelRatio || 1, 2);

  const effectiveDpr = clampCanvasDpr(state.width, state.height, state.dpr);
  state.canvas.width = Math.max(1, Math.floor(state.width * effectiveDpr));
  state.canvas.height = Math.max(1, Math.floor(state.height * effectiveDpr));
  state.context.setTransform(effectiveDpr, 0, 0, effectiveDpr, 0, 0);

  const baseNodeCount = nodeCountForArea(state.width * state.height);
  let neededNodes = baseNodeCount;
  if (state.touchViewport) {
    neededNodes = Math.max(16, neededNodes - 4);
  }
  if (state.touchDarkBoost) {
    neededNodes += 1;
  }
  if (state.nodes.length !== neededNodes) {
    state.nodes = createNodes(neededNodes, state.width, state.height);
    return;
  }

  clampNodes(state.nodes, state.width, state.height);
}

function resolveFrameScale(state, timestamp) {
  if (state.previousTimestamp === 0) {
    state.previousTimestamp = timestamp;
    return 1;
  }

  const frameScale = Math.min((timestamp - state.previousTimestamp) / 16.667, 2.2);
  state.previousTimestamp = timestamp;
  return frameScale;
}

function updatePointerSmoothing(state) {
  state.pointerX += (state.pointerTargetX - state.pointerX) * 0.05;
  state.pointerY += (state.pointerTargetY - state.pointerY) * 0.05;
}

function updateNodes(state, frameScale) {
  const parallaxX = state.pointerX * 8;
  const parallaxY = state.pointerY * 6;

  for (const node of state.nodes) {
    node.x += node.vx * frameScale;
    node.y += node.vy * frameScale;

    if (node.x < 0 || node.x > state.width) {
      node.vx *= -1;
      node.x = clamp(node.x, 0, state.width);
    }

    if (node.y < 0 || node.y > state.height) {
      node.vy *= -1;
      node.y = clamp(node.y, 0, state.height);
    }

    node.ox = node.x + parallaxX * node.depth;
    node.oy = node.y + parallaxY * node.depth;
  }
}

function drawNodeLinks(state, maxDistSq) {
  const nodes = state.nodes;
  for (let index = 0; index < nodes.length; index += 1) {
    const fromNode = nodes[index];
    for (let next = index + 1; next < nodes.length; next += 1) {
      drawNodeLink(state, fromNode, nodes[next], maxDistSq, false);
    }
  }
}

function pairKey(indexA, indexB) {
  const a = Math.min(indexA, indexB);
  const b = Math.max(indexA, indexB);
  return (a << 8) | b;
}

function nearestNodeIndexes(state, fromIndex, maxDistSq, limit) {
  const source = state.nodes[fromIndex];
  let firstIndex = -1;
  let secondIndex = -1;
  let firstDist = Number.POSITIVE_INFINITY;
  let secondDist = Number.POSITIVE_INFINITY;

  for (const [index, node] of state.nodes.entries()) {
    if (index === fromIndex) {
      continue;
    }
    const distSq = linkDistanceSquared(source, node);
    if (distSq > maxDistSq) {
      continue;
    }

    if (distSq < firstDist) {
      secondDist = firstDist;
      secondIndex = firstIndex;
      firstDist = distSq;
      firstIndex = index;
      continue;
    }

    if (limit > 1 && distSq < secondDist) {
      secondDist = distSq;
      secondIndex = index;
    }
  }

  if (limit <= 1) {
    return firstIndex >= 0 ? [firstIndex] : [];
  }

  const result = [];
  if (firstIndex >= 0) {
    result.push(firstIndex);
  }
  if (secondIndex >= 0) {
    result.push(secondIndex);
  }
  return result;
}

function drawMobileDarkSequenceLinks(state, maxDistSq) {
  if (!state.touchDarkBoost || state.nodes.length < 6) {
    return;
  }
  drawDeliberatePairLinks(state, maxDistSq, true);
}

// Shared deliberate-pair line algorithm. Originally introduced for mobile
// dark mode (iPhone) where the touchDarkBoost branch gave visibly cleaner
// triangulation than the desktop O(n^2) distance-fade. Promoted to also
// run on desktop dark mode 2026-06-01: the desktop distance-fade was
// producing line alpha ~0.02 at the user's current hero size, leaving the
// 'computer-science' lattice nearly invisible in macOS Safari. Deliberate
// pairs (nearest neighbors + Fibonacci-offset siblings) draw far fewer
// edges than O(n^2) but each one paints at a usable alpha, which matches
// the iPhone result the brand owner already approves of.
function drawDeliberatePairLinks(state, maxDistSq, touchDarkBoost) {
  if (state.nodes.length < 6) {
    return;
  }

  const localMaxDistSq = maxDistSq * 0.5;
  const fibMaxDistSq = maxDistSq * 0.62;
  const fibOffsets = [2, 3, 5];
  const drawnPairs = new Set();

  for (const [index] of state.nodes.entries()) {
    const nearestLimit = index % 2 === 0 ? 2 : 1;
    for (const neighborIndex of nearestNodeIndexes(state, index, localMaxDistSq, nearestLimit)) {
      drawDeliberateLink(state, drawnPairs, index, neighborIndex, localMaxDistSq, touchDarkBoost);
    }

    for (const offset of fibOffsets) {
      if (offset === 5 && index % 2 !== 0) {
        continue;
      }
      drawDeliberateLink(state, drawnPairs, index, index + offset, fibMaxDistSq, touchDarkBoost);
    }
  }

  for (let index = 0; index + 2 < state.nodes.length; index += 3) {
    drawDeliberateLink(state, drawnPairs, index, index + 2, fibMaxDistSq, touchDarkBoost);
  }
}

function drawDeliberateLink(state, drawnPairs, indexA, indexB, maxDistSq, touchDarkBoost) {
  if (indexA === indexB || indexB < 0 || indexB >= state.nodes.length) {
    return;
  }

  const key = pairKey(indexA, indexB);
  if (drawnPairs.has(key)) {
    return;
  }

  const fromNode = state.nodes[indexA];
  const toNode = state.nodes[indexB];
  if (linkDistanceSquared(fromNode, toNode) > maxDistSq) {
    return;
  }

  drawnPairs.add(key);
  drawNodeLink(state, fromNode, toNode, maxDistSq, touchDarkBoost);
}

function drawNodeLink(state, a, b, maxDistSq, touchDarkBoost) {
  const distSq = linkDistanceSquared(a, b);
  if (distSq > maxDistSq) {
    return;
  }

  const intensity = 1 - distSq / maxDistSq;
  const style = resolveNodeLinkStyle(state, a, b, intensity, touchDarkBoost);

  state.context.beginPath();
  state.context.moveTo(a.ox, a.oy);
  state.context.lineTo(b.ox, b.oy);
  state.context.strokeStyle = style.strokeStyle;
  state.context.lineWidth = style.lineWidth;
  state.context.stroke();
}

function linkDistanceSquared(a, b) {
  const dx = a.ox - b.ox;
  const dy = a.oy - b.oy;
  return dx * dx + dy * dy;
}

function isDesktopDarkMode(state) {
  return !state.touchViewport && !document.documentElement.classList.contains('switch');
}

function resolveLinkScale(touchDarkBoost, touchLightBoost, darkScale, lightScale) {
  if (touchDarkBoost) {
    return darkScale;
  }
  if (touchLightBoost) {
    return lightScale;
  }
  return 1;
}

function isWarmLink(touchDarkBoost, a, b) {
  if (touchDarkBoost) {
    return a.gold && b.gold;
  }
  return a.gold || b.gold;
}

function resolveLinkColorChannels(touchDarkBoost, touchLightBoost, desktopDark, warm) {
  if (touchDarkBoost || desktopDark) {
    // Brighter palette for any dark-mode viewer (mobile or desktop).
    // Matches what the iPhone screenshot looks like on macOS Safari.
    if (warm) {
      return { red: 232, green: 198, blue: 116 };
    }
    return { red: 105, green: 186, blue: 244 };
  }

  if (warm) {
    return { red: 207, green: 173, blue: 105 };
  }

  if (touchLightBoost) {
    return { red: 78, green: 164, blue: 243 };
  }

  return { red: 84, green: 154, blue: 229 };
}

function resolveLinkAlphaWidth(touchDarkBoost, touchLightBoost, desktopDark, warm, intensity) {
  // Curve the intensity so lines near maxDist still paint at a usable alpha
  // instead of fading to invisibility. Math.pow(intensity, 0.55) keeps
  // close-range lines near 1.0 while lifting mid-range from ~0.3 to ~0.5.
  const curvedIntensity = Math.pow(Math.max(0, Math.min(1, intensity)), 0.55);

  let baseAlpha = warm ? 0.24 : 0.2;
  let baseWidth = warm ? 0.82 : 0.7;
  let alphaScale = 1;
  let widthScale = 1;

  if (touchDarkBoost) {
    alphaScale = 1.3;
    widthScale = 1.1;
  } else if (desktopDark) {
    // Desktop dark mode was previously falling into the bare base values,
    // which produced ~0.02 alpha at typical hero sizes. Match the mobile
    // dark-mode visibility budget.
    baseAlpha = warm ? 0.62 : 0.55;
    baseWidth = warm ? 1.0 : 0.88;
    alphaScale = 1;
    widthScale = 1;
  } else if (touchLightBoost) {
    alphaScale = 1.52;
    widthScale = 1.32;
  }

  const alpha = Math.min(1, curvedIntensity * baseAlpha * alphaScale);
  const lineWidth = baseWidth * widthScale;
  return { alpha, lineWidth };
}

function resolveNodeLinkStyle(state, a, b, intensity, touchDarkBoost) {
  const touchLightBoost = state.touchViewport && !touchDarkBoost;
  const desktopDark = isDesktopDarkMode(state);
  const warm = isWarmLink(touchDarkBoost, a, b);
  const color = resolveLinkColorChannels(touchDarkBoost, touchLightBoost, desktopDark, warm);
  const { alpha, lineWidth } = resolveLinkAlphaWidth(
    touchDarkBoost,
    touchLightBoost,
    desktopDark,
    warm,
    intensity
  );
  return {
    strokeStyle: `rgba(${color.red}, ${color.green}, ${color.blue}, ${alpha})`,
    lineWidth,
  };
}

function resolveNodeDotColor(gold, touchDarkBoost, touchLightBoost) {
  if (touchDarkBoost) {
    return gold ? '255, 223, 138' : '156, 214, 255';
  }
  if (touchLightBoost) {
    return gold ? '223, 184, 70' : '78, 161, 250';
  }
  return gold ? '213, 173, 54' : '97, 173, 250';
}

function drawNodeDots(state) {
  const touchLightBoost = state.touchViewport && !state.touchDarkBoost;
  const alphaBoost = resolveLinkScale(state.touchDarkBoost, touchLightBoost, 1.12, 1.28);
  const radiusBoost = resolveLinkScale(state.touchDarkBoost, touchLightBoost, 1.12, 1.14);
  for (const node of state.nodes) {
    const alpha = Math.min(1, (node.gold ? 0.82 : 0.72) * alphaBoost);
    const color = resolveNodeDotColor(node.gold, state.touchDarkBoost, touchLightBoost);
    state.context.beginPath();
    state.context.arc(node.ox, node.oy, node.radius * radiusBoost, 0, Math.PI * 2);
    state.context.fillStyle = `rgba(${color}, ${alpha})`;
    state.context.fill();
  }
}

function renderConstellationFrame(timestamp, state) {
  if (!state.running) {
    return;
  }

  // Throttle mobile draw cadence to cut long main-thread tasks.
  if (
    state.targetFrameInterval > 0 &&
    state.lastRenderTimestamp > 0 &&
    timestamp - state.lastRenderTimestamp < state.targetFrameInterval
  ) {
    state.frameHandle = globalThis.requestAnimationFrame(state.renderFrame);
    return;
  }

  state.lastRenderTimestamp = timestamp;
  const frameScale = resolveFrameScale(state, timestamp);
  updatePointerSmoothing(state);

  state.context.clearRect(0, 0, state.width, state.height);

  const desktopDark = isDesktopDarkMode(state);
  // Desktop hero is much larger than mobile, so the max-distance floor
  // needs to scale with it for the deliberate-pair lattice to reach
  // enough neighbors. Mobile keeps its original floor.
  const baseMaxDist = desktopDark
    ? Math.max(110, Math.min(170, state.width * 0.32))
    : Math.max(78, Math.min(132, state.width * 0.27));
  const touchLightBoost = state.touchViewport && !state.touchDarkBoost;
  let maxDist = baseMaxDist;
  if (state.touchDarkBoost) {
    maxDist = baseMaxDist * 1.08;
  } else if (touchLightBoost) {
    maxDist = baseMaxDist * 1.24;
  }
  const maxDistSq = maxDist * maxDist;

  updateNodes(state, frameScale);
  if (state.touchDarkBoost) {
    drawMobileDarkSequenceLinks(state, maxDistSq);
  } else if (desktopDark) {
    // Use the same deliberate-pair algorithm as mobile dark mode,
    // but pass false for touchDarkBoost so palette/width resolve to
    // the desktop-dark branch in resolveNodeLinkStyle.
    drawDeliberatePairLinks(state, maxDistSq, false);
  } else {
    drawNodeLinks(state, maxDistSq);
  }
  drawNodeDots(state);

  state.frameHandle = globalThis.requestAnimationFrame(state.renderFrame);
}

function stopConstellation(state) {
  if (!state.running) {
    return;
  }

  state.running = false;
  state.previousTimestamp = 0;
  state.lastRenderTimestamp = 0;
  if (state.frameHandle) {
    globalThis.cancelAnimationFrame(state.frameHandle);
    state.frameHandle = 0;
  }
}

function startConstellation(state) {
  if (state.running || state.reducedMotion || document.hidden) {
    return;
  }

  if (!state.inView) {
    return;
  }

  state.running = true;
  state.previousTimestamp = 0;
  state.lastRenderTimestamp = 0;
  state.frameHandle = globalThis.requestAnimationFrame(state.renderFrame);
}

function applyMotionPreference(state) {
  if (state.reducedMotion) {
    stopConstellation(state);
    state.canvas.style.display = 'none';
    state.context.clearRect(0, 0, state.width, state.height);
    return;
  }

  state.canvas.style.removeProperty('display');
  resizeConstellation(state);
  startConstellation(state);
}

function updatePointerTarget(state, event) {
  const rect = state.logoRect || state.logo.getBoundingClientRect();
  state.pointerTargetX = (event.clientX - rect.left) / rect.width - 0.5;
  state.pointerTargetY = (event.clientY - rect.top) / rect.height - 0.5;
}

function bindPointerEvents(state) {
  state.logo.addEventListener('pointermove', (event) => {
    updatePointerTarget(state, event);
  }, { passive: true });

  state.logo.addEventListener('pointerleave', () => {
    state.pointerTargetX = 0;
    state.pointerTargetY = 0;
  }, { passive: true });
}

function bindVisibilityEvents(state) {
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      stopConstellation(state);
      return;
    }
    startConstellation(state);
  });
}

function bindMotionPreferenceEvents(state) {
  if (!state.motionQuery || typeof state.motionQuery.addEventListener !== 'function') {
    return;
  }

  state.motionQuery.addEventListener('change', (event) => {
    state.reducedMotion = event.matches;
    applyMotionPreference(state);
  });
}

function bindResizeEvents(state) {
  if (typeof ResizeObserver === 'function') {
    const resizeObserver = new ResizeObserver(() => {
      resizeConstellation(state);
    });
    resizeObserver.observe(state.logo);
    return;
  }

  globalThis.addEventListener(
    'resize',
    () => {
      resizeConstellation(state);
    },
    { passive: true }
  );
}

function bindIntersectionEvents(state) {
  if (typeof IntersectionObserver !== 'function') {
    return;
  }

  const intersectionObserver = new IntersectionObserver(
    (entries) => {
      state.inView = entries[0] ? entries[0].isIntersecting : true;
      if (!state.inView) {
        stopConstellation(state);
        return;
      }
      startConstellation(state);
    },
    { threshold: 0.1 }
  );

  intersectionObserver.observe(state.logo);
}
