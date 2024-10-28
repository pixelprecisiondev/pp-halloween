import React, { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import './App.scss'
import { formatPumpkins, isEnvBrowser } from '../utils/misc'
import { useNuiEvent } from '../hooks/useNuiEvent'
import useKey from '../hooks/useKey'
import { fetchNui } from '../utils/fetchNui'
import { FaCrown } from 'react-icons/fa'
import { GiPumpkin } from "react-icons/gi";
import { MdClose } from "react-icons/md";

type rankingProps = {
    total: number
    data: {
        identifier: string
        name: string
        pumpkins: number
    }[]
    player: {
        pumpkins: number
        place: number
    }
}

const App = () => {
    const [isVisible, setIsVisible] = useState(isEnvBrowser())
    const [rankingData, setRankingData] = useState<rankingProps | null>(null)

    useNuiEvent('open', (data: rankingProps) => {
        setRankingData(data)
        setIsVisible(true)
    })

    const handleClose = () => {
        fetchNui('close')
        setRankingData(null)
        setIsVisible(false)
    }

    useKey('Escape', handleClose)

    return (
        <div
            className="nui-wrapper"
            style={{
                backgroundImage: isEnvBrowser() ? 'url(https://i.imgur.com/3pzRj9n.png)' : 'none',
            }}
        >
            <AnimatePresence>
                {isVisible && rankingData && (
                    <motion.div
                        className="halloween-container"
                        animate={{ opacity: 1, scale: 1 }}
                        initial={{ opacity: 0, scale: 0.6 }}
                        exit={{ opacity: -0.1, scale: 0.4 }}
                        transition={{
                            type: 'spring',
                            stiffness: 100,
                            duration: 0.5,
                            exit: { duration: 1 },
                        }}
                    >
                        <MdClose onClick={handleClose} className="close-icon"/>
                        <img src="./images/title.png" alt="title" className="title" />
                        <img src="./images/pngegg.png" alt="bats" className="bats" />
                        <div className="ranking-wrapper">
                            <h1>Ranking</h1>
                            <h4 className="your-place">
                                Your Place: {rankingData.player.place} (
                                {formatPumpkins(rankingData.player.pumpkins)})
                            </h4>
                            <div className="ranking-list">
                                {rankingData.data.map((item, index) => (
                                    <div className="ranking-list-item" key={item.identifier}>
                                        <p className="index">{index + 1}.</p>
                                        <p className="name">
                                            {item.name}{' '}
                                            {index === 0 && <FaCrown className="crown" />}
                                        </p>

                                        <p className="pumpkins">
                                            {formatPumpkins(item.pumpkins)}
                                            <GiPumpkin/>
                                        </p>
                                    </div>
                                ))}
                            </div>
                            <p className='more-entries'>
                                And ({rankingData.total - rankingData.data.length}) more...
                            </p>
                            <img src="./images/bottom-pumpkins.png" alt="" className="bottom" />
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    )
}

export default App
