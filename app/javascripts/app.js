import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

import relay_artifacts from '../../build/contracts/Relay.json'
var Relay=contract(relay_artifacts);


var accounts;
var account;
var relay;
var frequency=0;
var submitNum=0;
var currentBlockNum=0;
var EP=require('eth-proof');

var eP = new EP(new Web3.providers.HttpProvider("https://gmainnet.infura.io"));
var sideChain=new Web3(new Web3.providers.HttpProvider("https://gmainnet.infura.io"));
var mainChain=new Web3(new Web3.providers.HttpProvider("http://localhost:7545"));



window.App = {
  start: function() {
    var self = this;
      App.setConfig()
    if(frequency==0 ||submitNum==0){
      window.location.href="./app/admin.html";
    }
    else{


      Relay.setProvider(new Web3.providers.HttpProvider("http://localhost:7545"));
      App.submitBHeader2MChain();
      //App.listen_block();
    }



    // var transaction = sideChain.eth.getTransaction("0x74bdf5450025b8806d55cfbb9b393dce630232f5bf87832ae6b675db9d286ac3");
    // console.log(transaction);


  },
  listen_block:function(){
    setInterval("App.submitBHeader2MChain()",frequency);
  },
  setStatus: function(message) {
    var status = document.getElementById("status");
    status.innerHTML = message;
  },

  setConfig:function(){
    var url=location.search;
    var request=new Object();
    Request["frequency"]=0;
    Request["submitNum"]=0;

    if(url.indexOf("?")!=-1){
      var str=url.substr(1);
      var strs=str.split("&");

      for(var i=0;i<strs.length;i++){

        Request[strs[i ].split("=")[0]]=unescape(strs[i].split("=")[1]);
      }
    }
    frequency=Request["frequency"];
    submitNum=Request["submitNum"];

  },

  segmentPrefixAndRlpvalue:function(value){
      var prefix = 0;
      var rlpvalue = 0;
      var base1 = parseInt('7f', 16);
      var base2 = parseInt('b7', 16);
      var base3 = parseInt('bf', 16);
      var s = parseInt(String(value).substring(0, 2), 16);

      if ( s <= base1 ){  // rule 1
          return String(prefix)+','+value;
      }
      else if ( s <= base2 ){  // rule 2
          if ( value.length < 3){
              return String(prefix)+','+value;
          }
          prefix = value.substring(0, 2);
          rlpvalue = value.substring(2, value.length);
          return prefix+','+rlpvalue;
      }
      else if ( s <= base3 ){  // rule 3
          var skiplength = s - base2;
          prefix = value.substring(0, 2+(skiplength*2));
          rlpvalue = value.substring(2+(skiplength*2), value.length);
          return prefix+','+rlpvalue;
      }
      else{
          alert('prefix out of range');
      }
  },
  getPath:function(value){
    var i;
    var temp_array = [];
    for (i=0; i<value.length; i++) {
      temp_array.push(parseInt(value[i], 16));
    }
    temp_array.push(1);
    return temp_array;
},
  submitBHeader2MChain:function(){

    var blockhash;
    var prevBlockHash;
    var stateRoot;
    var txRoot;

    sideChain.eth.getBlockNumber(function(error, result){
      if(!error){
        var blockNumber=4012390;//result;


        // var transaction = sideChain.eth.getTransaction("0x74bdf5450025b8806d55cfbb9b393dce630232f5bf87832ae6b675db9d286ac3");
        // console.log(transaction);
        currentBlockNum=4012379;
        if(blockNumber!=currentBlockNum){
          for(var i=currentBlockNum;i<=blockNumber;i++){
            sideChain.eth.getBlock(i, function(error, result){
              if(!error){
                  blockhash=result.hash;
                  prevBlockHash=result.parentHash;
                  stateRoot=result.stateRoot;
                  txRoot=result.transactionsRoot;
                  // console.log('blockhash',blockhash);
                  // console.log('prevBlockHash',prevBlockHash);
                  // console.log('stateRoot',stateRoot);
                  // console.log('txRoot',txRoot);
                  Relay.deployed().then(function(instance){
                  var relayinstance=instance;
                  var accounts=new Web3(web3.currentProvider).eth.accounts;
                  account=accounts[0];
                  return relayinstance.submitBlock(blockhash,prevBlockHash,stateRoot,txRoot,{from:account,gas:210000}).catch(function(e) {
                    console.log(e);
                  });
                })
                currentBlockNum=blockNumber;
              }
              else
              console.error(error);
            });
          }
        }
      }
      else{
        console.error(error);
      }
     });
  },

  verify:function(){

    var self = this;
    var blockhash;
    var stack;
    var path;
    var value;
    var prefix;
    var rlpValue;
    var segmentValue;
    var txHash=document.getElementById("input").value
    eP.getTransactionProof(txHash).then((result)=>{
        var p=result;
        blockhash="0x"+Buffer.from(p.blockHash).toString('hex');
        stack="0x"+Buffer.from(p.parentNodes).toString('hex');
        path=App.getPath(Buffer.from(p.path).toString('hex'));
        value=Buffer.from(p.value).toString('hex');
        segmentValue=App.segmentPrefixAndRlpvalue(value);
        prefix="0x"+segmentValue.split(',')[0];
        rlpValue="0x"+segmentValue.split(',')[1];

        //txRoot='0x' + Buffer.from(p.header[4]).toString('hex');
        console.log('blockhash：'+blockhash);
        console.log('stack：'+stack);
        console.log('path：',path);
        console.log('prefix：',prefix);
        console.log('rlpValue：',rlpValue);

        Relay.deployed().then(function(instance){
          relay=instance;
          //return relay.checkTxProof.call(blockhash, stack, path, prefix, rlpValue)
          return relay.checkTxProof.call(blockhash, stack, path, prefix, rlpValue).then(res=>{
            if(res)
            {App.setStatus("该交易已在主链存证");}
            else {
              App.setStatus("该交易未在主链存证");
            }
          }).catch(function(e) {
            console.log(e);
          });
        })

      })
  },

};

window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear or you have 0 MetaCoin, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://127.0.0.1:9545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:9545"));
  }

  App.start();
});
