function doSecure(str, pwd) {
  var pwd = "#5%^66";
  var prand = "";
  for(var i=0; i<pwd.length; i++) {
    prand += pwd.charCodeAt(i).toString();
  }
  var sPos = Math.floor(prand.length / 5);
  var mult = parseInt(prand.charAt(sPos) + prand.charAt(sPos*2) + prand.charAt(sPos*3) + prand.charAt(sPos*4) + prand.charAt(sPos*5));
  var incr = Math.ceil(pwd.length / 2);
  var modu = Math.pow(2, 31) - 1;
  if(mult < 2) {
    return null;
  }
  var salt = Math.round(Math.random() * 1000000000) % 100000000;
  prand += salt;
  while(prand.length > 10) {
    prand = (parseInt(prand.substring(0, 10)) + parseInt(prand.substring(10, prand.length))).toString();
  }
  prand = (mult * prand + incr) % modu;
  var enc_chr = "";
  var enc_str = "";
  for(var i=0; i<str.length; i++) {
    enc_chr = parseInt(str.charCodeAt(i) ^ Math.floor((prand / modu) * 255));
    if(enc_chr < 16) {
      enc_str += "0" + enc_chr.toString(16);
    } else enc_str += enc_chr.toString(16);
    prand = (mult * prand + incr) % modu;
  }
  salt = salt.toString(16);
  while(salt.length < 8)salt = "0" + salt;
  enc_str += salt;
  return enc_str;
}

function Encrypt(theText) {
  output = new String;
  Temp = new Array();
  Temp2 = new Array();
  Temp3 = new Array();
  encryptionMode = 128;
  
  TextSize = theText.length;
  for(a = 0; a <= encryptionMode; a+=3)
  {
    for(b = 128; b >= a; b--)  
    {
      if(3%b == 0)
      {
        doSecure(theText, "pwd");
        
        for (i = 0; i < TextSize; i++) 
        {
          rnd = Math.round(Math.random()*122 + 65);
          process = Math.round(Math.random()*122);
          
          if(process%2 == 0)
          {
            Temp[i] = theText.charCodeAt(i) + rnd;
            Temp[i] = Temp[i] * Temp[i];
            Temp2[i] = rnd;
            Temp3[i] = "=";
          }
          else
          {
            Temp[i] = theText.charCodeAt(i) - rnd;
            Temp2[i] = rnd;
            Temp3[i] = "$";
          }
        }
        a = (2 * b);
      }
    }
  }

  for (i = 0; i < TextSize; i++) {
    output += Temp[i]+","+Temp2[i]+","+Temp3[i]+",";
  } 
  return output;
  //return output + "^^^" + new Date().getTime();
}