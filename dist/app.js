const cars = [
  { name: 'VORTEX GT', type: 'STREET SPORT · CLASS A', speed: 266, accel: '3.8', handling: 92, color: '#db4e45', darker: '#8f2632' },
  { name: 'NOVA R8', type: 'SUPERCAR · CLASS S', speed: 304, accel: '3.2', handling: 89, color: '#35a8c8', darker: '#176176' },
  { name: 'FALCON XR', type: 'MUSCLE · CLASS A', speed: 281, accel: '3.5', handling: 78, color: '#e8aa45', darker: '#8d5522' },
  { name: 'ZENITH S', type: 'HYPER · CLASS S', speed: 328, accel: '2.9', handling: 95, color: '#d5d9df', darker: '#737b8c' },
  { name: 'NIGHTSHADE', type: 'STREET SPORT · CLASS A', speed: 294, accel: '3.4', handling: 96, color: '#7657b9', darker: '#3e2d71' },
  { name: 'TORQUE RS', type: 'RALLY · CLASS B', speed: 273, accel: '3.6', handling: 98, color: '#68ad72', darker: '#356842' },
  { name: 'APEX V12', type: 'HYPER · CLASS S', speed: 344, accel: '2.7', handling: 87, color: '#f0e5d6', darker: '#857b73' },
  { name: 'ECLIPSE GT', type: 'STREET SPORT · CLASS A', speed: 298, accel: '3.3', handling: 94, color: '#e56ca3', darker: '#813b61' },
  { name: 'BLAZE 900', type: 'SUPERCAR · CLASS S', speed: 321, accel: '3.0', handling: 91, color: '#ef7646', darker: '#8c3d2c' },
  { name: 'PHANTOM Z', type: 'HYPER · CLASS S', speed: 352, accel: '2.6', handling: 86, color: '#4d637f', darker: '#273547' },
]
const tracks = ['NEON HARBOR', 'ALPINE PASS', 'DUST DEVIL', 'PACIFIC RUN', 'AFTER HOURS']
let carIndex = 0
let trackIndex = 0
let toastTimer
const toast = document.querySelector('#toast')

function announce(message) {
  toast.textContent = message
  toast.classList.add('visible')
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => toast.classList.remove('visible'), 2600)
}

function showCar(index) {
  carIndex = index % cars.length
  const car = cars[carIndex]
  document.querySelector('#car-name').innerHTML = `${car.name.split(' ')[0]} <b>${car.name.split(' ').slice(1).join(' ')}</b>`
  document.querySelector('#car-class').textContent = car.type
  document.querySelector('#stat-speed').textContent = car.speed
  document.querySelector('#stat-accel').textContent = car.accel
  document.querySelector('#stat-handling').textContent = car.handling
  document.querySelector('#paint-light').setAttribute('stop-color', car.color)
  document.querySelector('#paint-dark').setAttribute('stop-color', car.darker)
  document.querySelector('.hero-index span:first-child').textContent = String(carIndex + 1).padStart(2, '0')
  document.querySelector('.hero-caption strong').innerHTML = `${car.name.split(' ')[0]}<br>AFTER HOURS.`
}

function showTrack() {
  document.querySelector('#track-name').textContent = tracks[trackIndex]
  document.querySelector('.track-progress span').style.width = `${(trackIndex + 1) * 20}%`
}

document.querySelector('#track-next').addEventListener('click', () => {
  trackIndex = (trackIndex + 1) % tracks.length
  showTrack()
})
document.querySelector('#drive-button').addEventListener('click', () => {
  const mode = document.querySelector('.mode-card.selected')?.dataset.mode || 'QUICK RACE'
  announce(`${mode} · ${tracks[trackIndex]} · GRID IS READY`)
})
document.querySelector('.add-credit').addEventListener('click', () => announce('Credits are earned on the streets. Time to race.'))
document.querySelectorAll('.mode-card').forEach(button => button.addEventListener('click', () => {
  document.querySelectorAll('.mode-card').forEach(card => card.classList.remove('selected'))
  button.classList.add('selected')
}))
document.querySelectorAll('.rail-nav a').forEach(link => link.addEventListener('click', () => {
  document.querySelectorAll('.rail-nav a').forEach(item => item.classList.remove('active'))
  link.classList.add('active')
}))

document.querySelector('#car-name').addEventListener('click', () => showCar(carIndex + 1))
showCar(0)
showTrack()
