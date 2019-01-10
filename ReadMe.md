# 1.Interface Description
## (1) VeRelayer Interface
1)	input：  
&nbsp; &nbsp; Set the listening frequency of VeRelayer(milliseconds): for example, set it to 1000, then, the listening frequency is per second.  
 &nbsp; &nbsp;Set the number of Relayer submission block headers: for example, set to 2, the content of the main chain deposit is to merge the two block headers into one, and store them in the main chain Relay Contract.(temporarily fixed to   
2)	Functions：Set parameters and perform the main chain deposit function.    
a)	The side chain depositor sets the listening frequency and the number of submission blocks acorrding to their own needs, and clicks the submit button.  
b)	After the submission, the main chain deposit function wil listen to the side chain block header at the set listening frequency, and call the submitBlock function in the Relay contract to store the currently uncerified block in the main chain's Relay contract. The gas required for this process is paid in the account that set in the app.js file.  
3)	output：None.  
![](/images/console.jpg)   
## (2) Sidechain Verification Platform Interface
1)	input: the hash of side chain's transaction.   
2)	Functions：side chain transaction verification function.   
a)	Firstly, the side chain user submits his own transaction hash on the side chain, then click on the query button.  
b)	Secondly, it will trigger the verify function in the app.js file. In this function, the Proof related parameters of this tranction are obtained by calling ethProof function, The right of this page shows the corresponding proof of a transaction what we printed in the console.   
c)	 Thirdly, instantiate the Relay contract in this function, then call the checkTxProof function in the Relay contract to verify.    
d)	Finaly, return true or false.    
3)	output: the app.js file shows whether the transaction is in the main chain on the pagd based on the returned value(bool).     
![](/images/test.jpg)  
# 2.Install and use
## (1) Install
Ganache v1.1.0  
Truffle v4.1.3 (core: 4.1.3)  
Solidity v0.4.19 (solc-js)  
MetaMask(chorme plugin)  
## (2) Use
1) Run 'truffle compile –reset' at the root directory of VeRealy.  
2) Run the Ganache client(the default port for windows is 7545, the default for Linux is 8545, here is 7545, the default port should be modified in truffle.js and app.js files).  
3) Run 'truffle migrate --reset' in the root directory of VeRelay.  
4) Run 'npm run dev' in the root directory of VeRelay
5) Open the localhost:8080 web page in a browser with MetaMask.  
