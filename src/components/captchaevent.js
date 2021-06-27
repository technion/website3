const DoomCaptcha = () => {
  const getAddress = () => {
    const encoded = "d!!jaG5pb25AbG9sd2FyZS5uZXQ=";
    return atob(encoded.replace("!!", "GV"));
  };

  const isSSR = typeof window === "undefined";

  if (isSSR) {
    return null;
  }

  window.addEventListener(
    "message",
    function (e) {
      if (e.origin.indexOf("vivirenremoto.github.io") > -1) {
        document.getElementById("doom_captcha").style.borderColor = "black";
        const item = document.getElementById("emailoutput");
        item.innerHTML = "Contact address: " + getAddress();
      }
    },
    false
  );
  return null;
};

export default DoomCaptcha;
