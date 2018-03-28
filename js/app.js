const canvas = document.querySelector('canvas');
const img = new Image;

img.src = 'img/loading.png';

img.onload = function() {
    setInterval( () => {
        glitch({
            seed:       0 + Math.random() * 3,
            quality:    97 + Math.random() * 2,
            amount:     Math.random() * 3,
            iterations: 1
        })
        .fromImage( img )
        .toDataURL()
        .then( function( dataURL ) {
            const target = document.querySelector('.loading');
            target.style.backgroundImage = `url(${dataURL})`;
        });
    }, 80);
}
