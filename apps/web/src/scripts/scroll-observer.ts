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
  const icon = document.querySelector<HTMLElement>('[data-showcase-icon]');

  if (!icon || steps.length === 0) return;

  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;

        const step = entry.target as HTMLElement;
        const visual = step.dataset.stepVisual;

        if (visual) {
          icon.style.opacity = '0';
          icon.style.transform = 'scale(0.8)';
          setTimeout(() => {
            icon.textContent = visual;
            icon.style.opacity = '1';
            icon.style.transform = 'scale(1)';
          }, 200);
        }

        for (const s of steps) {
          s.classList.toggle(
            'lg:border-indigo-500/30',
            s === step,
          );
          s.classList.toggle(
            'lg:bg-neutral-900/40',
            s === step,
          );
        }
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
