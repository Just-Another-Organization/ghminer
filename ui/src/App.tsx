import React, {FC, useEffect, useState} from 'react';
import './App.css'

const App: FC = () => {
  const [logs, setLogs] = useState<string[]>([]);
  const [minerStatus, setMinerStatus] = useState<string>('');

  async function getLogs() {
    const logs = await fetch('http://localhost:4567/logs').then((res) =>{
      return res.json()
    })
    setLogs(logs.result.split("|"))
    const last = logs.result.split("|").at(-2)
    setMinerStatus(last.toString())
  }

  useEffect(() => {
    getLogs();
    setInterval(() => {
      getLogs();
    }, 20000)

  }, []);


  function getMinerStatus(){
    return !minerStatus.includes('Miner ready');
  }

  // TODO CHANGE LOCALHOST WITH CONTAINER OR ENV FILE
  function startMining(){
    fetch('http://localhost:4567/mine');
  }

  return (
    <div className="container">
      <div className="d-flex align-items-baseline p-2 justify-content-evenly">
        {
          logs && minerStatus && (
            <>
              <p className="lead">
                Miner Status: { getMinerStatus() ? 'Active' : 'Inactive'}
              </p>
            </>
          )
        }
      <button type="button" className={"btn btn-success"} disabled={ getMinerStatus() } onClick={startMining}>Start Mining</button>
    </div>
      <div className="card  logs-wrapper py-3" >
        {
          logs.map( (log, i) => {
            return (
              <div key={i} className="row">
                <p className="row-message">{log}</p>
              </div>
            )
          })
        }
      </div>
    </div>

  );
};

export default App;

