function initRevealAnimations() {
  const elements = document.querySelectorAll<HTMLElement>('[data-reveal]');

  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add('revealed');
          observer.unobserve(entry.target);
        }
      }
    },
    { threshold: 0.15, rootMargin: '0px 0px -40px 0px' },
  );

  for (const el of elements) {
    el.classList.add('reveal-hidden');
    observer.observe(el);
  }
}

function initStickyShowcase() {
  const steps = document.querySelectorAll<HTMLElement>('.showcase-step');
  const screenImage = document.querySelector<HTMLImageElement>(
    '[data-showcase-screen-image]',
  );

  if (steps.length === 0) return;
  let activeStepIndex = 0;

  const setShowcaseContent = (step: HTMLElement) => {
    const nextImage = step.dataset.screenImage ?? '';
    if (screenImage && nextImage) screenImage.src = nextImage;
  };

  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;

        const step = entry.target as HTMLElement;
        const nextIndex = Number(step.dataset.stepIndex ?? 0);
        if (nextIndex === activeStepIndex) continue;

        setShowcaseContent(step);
        activeStepIndex = nextIndex;

      }
    },
    { threshold: 0.6 },
  );

  for (const step of steps) {
    observer.observe(step);
  }
}

function initPhoneParallax() {
  const root = document.querySelector<HTMLElement>('[data-phone-parallax-root]');
  if (!root) return; 
  if (root.dataset.parallaxReady === 'true') return;
  root.dataset.parallaxReady = 'true';

  const items = root.querySelectorAll<HTMLElement>('[data-parallax-item]');
  if (items.length === 0) return;

  let ticking = false;

  const updateParallax = () => {
    const rect = root.getBoundingClientRect();
    const viewportHeight = window.innerHeight;
    const sectionCenter = rect.top + rect.height / 2;
    const viewportCenter = viewportHeight / 2;
    const maxTravel = viewportHeight / 2 + rect.height / 2;
    const normalized = Math.min(
      1,
      Math.max(-1, (sectionCenter - viewportCenter) / maxTravel),
    );
    const baseShift = normalized * 300;

    for (const item of items) {
      const strength = Number(item.dataset.parallaxStrength ?? 1);
      const speed = 0.45 + strength * 0.24;
      const shiftY = baseShift * speed;
      item.style.transform = `translate3d(0, ${shiftY}px, 0)`;
    }

    ticking = false;
  };

  const scheduleUpdate = () => {
    if (ticking) return;
    ticking = true;
    window.requestAnimationFrame(updateParallax);
  };

  for (const item of items) {
    item.style.willChange = 'transform';
  }

  window.addEventListener('scroll', scheduleUpdate, { passive: true });
  window.addEventListener('resize', scheduleUpdate);
  scheduleUpdate();
}

function initScrollEffects() {
  initRevealAnimations();
  initStickyShowcase();
  initPhoneParallax();
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initScrollEffects, { once: true });
} else {
  initScrollEffects();
}

document.addEventListener('astro:page-load', initScrollEffects);
