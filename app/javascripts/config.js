
function readConfig(){
  frequency=document.getElementById("frequency").value;
  submitNum=document.getElementById("num").value;
  window.location.href="/index.html?frequency="+frequency+"&submitNum="+submitNum;

}
