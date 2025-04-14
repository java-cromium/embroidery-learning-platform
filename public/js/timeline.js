document.addEventListener('DOMContentLoaded', () => {
    const timelineItems = document.querySelectorAll('.timeline-item');
    
    // Initial visibility check
    timelineItems.forEach(item => {
        checkVisibility(item);
    });

    // Check visibility on scroll
    window.addEventListener('scroll', () => {
        timelineItems.forEach(item => {
            checkVisibility(item);
        });
    });

    function checkVisibility(element) {
        const rect = element.getBoundingClientRect();
        const windowHeight = window.innerHeight || document.documentElement.clientHeight;
        
        if (rect.top <= windowHeight * 0.75) {
            element.classList.add('timeline-visible');
        }
    }

    // Timeline navigation
    const navButtons = document.querySelectorAll('.timeline-nav-btn');
    navButtons.forEach(button => {
        button.addEventListener('click', () => {
            const targetYear = button.getAttribute('data-year');
            const targetElement = document.querySelector(`[data-year="${targetYear}"]`);
            targetElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
        });
    });
});
