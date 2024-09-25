document.addEventListener('DOMContentLoaded', (event) => {
    const themeToggle = document.getElementById('theme-toggle');
    const html = document.querySelector('html');
  
    if (!themeToggle || !html) {
      console.error('Required elements not found');
      return;
    }
  
    const currentTheme = localStorage.getItem('theme') || 'light';
    setTheme(currentTheme);
  
    themeToggle.addEventListener('click', () => {
      const theme = html.getAttribute('data-theme');
      const newTheme = theme === 'light' ? 'dark' : 'light';
      setTheme(newTheme);
    });
  
    function setTheme(newTheme) {
      html.classList.add('theme-transition');
      html.setAttribute('data-theme', newTheme);
      localStorage.setItem('theme', newTheme);
      updateButtonIcon(newTheme);
      
      // Remove transition class after the transition is complete
      setTimeout(() => {
        html.classList.remove('theme-transition');
      }, 300); // Adjust timing to match your CSS transition
    }
  
    function updateButtonIcon(theme) {
      const icon = themeToggle.querySelector('i');
      if (icon) {
        icon.className = theme === 'light' ? 'fas fa-moon' : 'fas fa-sun';
      }
    }
  });