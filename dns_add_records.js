(() => {
  function setReactInput(el, value) {
    const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
    setter.call(el, value);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }

  async function addRecord(host, type, value) {
    const addBtn = [...document.querySelectorAll('button,a,span')].find(e => (e.innerText||'').trim() === '添加记录');
    if (addBtn) addBtn.click();
    await new Promise(r => setTimeout(r, 800));

    const nameInput = document.querySelector('input[name="Name"]');
    const valueInput = document.querySelector('input[name="Value"]');
    if (!nameInput || !valueInput) return `missing_inputs_${host}`;

    setReactInput(nameInput, host);
    setReactInput(valueInput, value);

    if (type === 'CNAME') {
      const typeSel = [...document.querySelectorAll('div,span,button')].find(e => (e.innerText||'').trim() === 'A' && e.closest('tr'));
      // try dropdown for record type
      const switches = [...document.querySelectorAll('span,div,button')].filter(e => (e.innerText||'').trim() === 'A');
      if (switches.length) switches[0].click();
      await new Promise(r => setTimeout(r, 400));
      const cnameOpt = [...document.querySelectorAll('li,div,span,button')].find(e => (e.innerText||'').trim() === 'CNAME');
      if (cnameOpt) cnameOpt.click();
    }

    await new Promise(r => setTimeout(r, 500));
    const confirm = [...document.querySelectorAll('button,a,span')].find(e => (e.innerText||'').trim() === '确认');
    if (!confirm) return `no_confirm_${host}`;
    confirm.click();
    await new Promise(r => setTimeout(r, 1500));
    return `ok_${host}_${value}`;
  }

  const records = [
    ['@', 'A', '185.199.108.153'],
    ['@', 'A', '185.199.109.153'],
    ['@', 'A', '185.199.110.153'],
    ['@', 'A', '185.199.111.153'],
    ['www', 'CNAME', 'wangqiang269101-png.github.io']
  ];

  return (async () => {
    const results = [];
    for (const [host, type, value] of records) {
      results.push(await addRecord(host, type, value));
    }
    return JSON.stringify(results);
  })();
})();
