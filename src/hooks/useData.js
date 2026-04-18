import { useState, useEffect } from "react"
import { soilData } from "../map/fakeData"

export default function useData() {
  const [data, setData] = useState(null)

  useEffect(() => {
    setTimeout(() => {
      setData({ soil: soilData })
    }, 500)
  }, [])

  return data
}