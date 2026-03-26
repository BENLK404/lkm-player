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

document.addEventListener('DOMContentLoaded', () => {
  initRevealAnimations();
  initStickyShowcase();
});
