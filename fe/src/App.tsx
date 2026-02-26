import { useState, useEffect } from 'react'
import axios from 'axios'
import { SpinnerRoundFilled } from 'spinners-react';

interface Stock {
  percent_change: number,
  date: string,
  ticker: string,
  closing_price: number
}
function App() {
  const [loading, setLoading] = useState<boolean>(true)
  const [data, setData] = useState<Stock[] | undefined>()
  const [error, setError] = useState<string | undefined>()

  useEffect(()=>{
    const getData = async() =>{
      try {
        const result = await axios.get("https://tl087nedfk.execute-api.us-west-1.amazonaws.com/prod/movers")
        if (result) {
          setLoading(false)
          setData(result.data)
        }
        
      }catch(e) {
        setError("There has been an error with fetching information.")
        console.log(`There has been an error calling the API - ${e}`)
      }
    }

    getData()
  }, [])
  return (
    <>
      
        <h1>Stock Top-Movers</h1>
        <p>Data for the last 7 business days</p>
        {!error ? (
        <>
        {!loading && data ?
        (
          <table>
            <tr>
              <th>Date</th>
              <th>Ticker</th>
              <th>Closing Price</th>
              <th>% Change</th>
            </tr>
            { data.map((item, id)=>(
              <tr key={id} className={item.percent_change>0? "positive_row" : "negative_row"}>
                <td>{item.date}</td>
                <td>{item.ticker}</td>
                <td>${item.closing_price}</td>
                <td>{item.percent_change.toFixed(2)}%</td>
              </tr>
            ))
            }
          </table>
      ):
      <SpinnerRoundFilled size="200px" enabled={true} color="#1E90FF"/>
      }
      </>
      
      )
    :
    <>
    <div id="error">There has been an error fetching weekly data.</div>
    </>}
      
    </>
  )
}

export default App
