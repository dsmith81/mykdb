
/ server side functionality for spliting a query into chunks 
/ distributing that over multiple server processes
/ and recollating that into one result 
\d .server

/ list of handles to processes registered as slaves
/ processing requests will be partitioned and sent to these processes.
SLAVES:();

/ list of results for an in-progress processing request
RESULT:();

/ when a slave registers with this server, add the handle to send requests
register:{SLAVES,::.z.w;};

/ when a slave de-registers, remove the handle, stop sending requests to that client.
deregister:{SLAVES::SLAVES except x;};

/ do a remote execution asyncronously and receive the result asyncronously
/ handle is where to send the execution
/ func is the function to execute
/ args are the arguments to the function being executed
/ cb is the callback to handle the result when it is received from the slave
remote_exec:{[handle;func;args;cb]
	(neg handle) / send request asyncronously
		({ (neg .z.w)( / result is returned via async
			{[callback;result]callback result}; / call the callback with the result
			y;x . enlist z)}; / pass the callback name and the result of applying args to func
		func;cb;args)}; / send func, callback and args to remote process.


/ when a result is received from a slave
/ add it to the global state and handle if complete
insert_result:{[handle_done;chunk]

	RESULT,::enlist (.z.w;chunk); / add the result to global state
	if[(count SLAVES)=count RESULT;handle_done[RESULT]]; / if all expected result chunks recieved, handle done
  };

/ called once all results have been received, 
/ process individual result chunks into complete result set
process_complete:{[rebuild;result]

	/ get the result chunks into correct order
	/ we know they were sent itemwise to each slave handle
	/ so we sort them based on the handle from which the result chunk was recieved from
	/ result[;0] is handle the result was recieved from
	/ result[;1] is the actual result chunk
	sorted_chunks:result[;1][SLAVES?result[;0]];

	/ rebuild the overall result by calling user defined rebuild function
	/ maps List<R> to R
	res:rebuild @ sorted_chunks;
	
	/ res is complete result
	show ("done: "; res);

  };

\d .

/ if a slave disappears we have to de-register it
.z.pc:{.server.deregister[x]};



/ entry point for clients to request a query be processed in parallel over remote instances
/ data is the data to do the processing on
/ divide is a function that splits data into smaller chunks for parallel processing
/ divide should match {[num_chunks;data] ... } and divide data into num_chunks chunks for processing
/ should map T to List<T>.
/ process is the function to apply to the data.
/ process should map T (input data type) to R (output result type).
/ rebuild is the inverse of divide.
/ rebuild should take a list containing the individual result objects and build a complete result.
/ should map List<R> to R.
distribute:{[data;divide;process;rebuild]

	chunks:divide[count .server.SLAVES;data];
	.server.RESULT:();
	.server.remote_exec[;process;.server.insert_result[.server.process_complete[rebuild]];] ./: flip (.server.SLAVES;chunks);

 };

/ examples
divide:{[chunks;input] (chunks; 0N)#input};
rebuild:raze;

