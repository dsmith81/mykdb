\d .slave

SERVER:-1;

/ register this process as a slave
/ remote server will send processing requests to this instance.
register:{[server] 

    if[not .slave.SERVER=-1;'"already registered ... please de-register"];
    .slave.SERVER:hopen server;
    .slave.SERVER(`.server.register;0);

 };

/ de-register this process as a slave
deregister:{hclose .slave.SERVER; .slave.SERVER:-1;}

\d .

/ if the server goes away, reset the state
.z.pc:{ if[.slave.SERVER=x; .slave.SERVER::-1];};